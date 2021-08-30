On 2017-06-04, replication packet #104949 broke replication for all live data
feed users. This document describes how I debugged that issue. (Note that it
involved the old dbmirror, not dbmirror2.)

Users applying this packet would have encountered the following error (taken
from MBS-9366):

```
'UPDATE "musicbrainz"."artist_alias" SET "artist" = ?, "begin_date_day" = ?, "begin_date_month" = ?, "begin_date_year" = ?, "edits_pending" = ?, "end_date_day" = ?, "end_date_month" = ?, "end_date_year" = ?, "ended" = ?, "id" = ?, "last_updated" = ?, "locale" = ?, "name" = ?, "primary_for_locale" = ?, "sort_name" = ?, "type" = ? WHERE "artist" = ? AND "id" = ? AND "type" = ?'
(347312 0 f 132184 2017-06-04 16:00:54.312309+00 ja 栄喜 t ひでき 1 994279 132184 1)
23505 DBD::Pg::st execute failed: ERROR: duplicate key value violates unique constraint "artist_alias_idx_primary"
DETAIL: Key (artist, locale)=(347312, ja) already exists.
```

The `artist_alias_idx_primary` unique constraint ensures that only one alias is
marked as "primary" for each locale. Somehow, the replication packet tried to
insert two aliases marked primary for the same locale (ja).

I had a look at the offending data contained in the packet:

```
300209584   t   "id"='132183' "artist"='347312' "type"='1' 
300209584   f   "id"='132183' "artist"='347312' "name"='CHACK' "locale"='ja' "edits_pending"='0' "last_updated"='2017-06-04 16:00:54.312309+00' "type"='1' "sort_name"='チャック' "begin_date_year"= "begin_date_month"= "begin_date_day"= "end_date_year"= "end_date_month"= "end_date_day"= "primary_for_locale"='f' "ended"='f' 
300209585   t   "id"='132183' "artist"='994271' "type"='1' 
300209585   f   "id"='132183' "artist"='347312' "name"='CHACK' "locale"='ja' "edits_pending"='0' "last_updated"='2017-06-04 16:00:54.312309+00' "type"='1' "sort_name"='チャック' "begin_date_year"= "begin_date_month"= "begin_date_day"= "end_date_year"= "end_date_month"= "end_date_day"= "primary_for_locale"='t' "ended"='f' 
300209586   t   "id"='132184' "artist"='994279' "type"='1' 
300209586   f   "id"='132184' "artist"='347312' "name"='栄喜' "locale"='ja' "edits_pending"='0' "last_updated"='2017-06-04 16:00:54.312309+00' "type"='1' "sort_name"='ひでき' "begin_date_year"= "begin_date_month"= "begin_date_day"= "end_date_year"= "end_date_month"= "end_date_day"= "primary_for_locale"='t' "ended"='f' 
```

For clarity, I simplified the IDs and removed irrelevant data:

```
1   keys   "id"='11' "artist"='111' 
1   data   "id"='11' "artist"='111' "name"='CHACK' "locale"='ja' "primary_for_locale"='f' 
2   keys   "id"='11' "artist"='222' 
2   data   "id"='11' "artist"='111' "name"='CHACK' "locale"='ja' "primary_for_locale"='t' 
3   keys   "id"='22' "artist"='333' 
3   daya   "id"='22' "artist"='111' "name"='栄喜' "locale"='ja' "primary_for_locale"='t' 
```

The first column is a sequence ID which orders the operations within a
transaction. The second column indicates whether the row contains only key
data (used to indentify and select a row for updating) or all data for the
operation.

These operations are for the `artist_alias` table. I can see that the aliases'
artists are all being changed to the same ID, so they must be for an artist
merge: edit #45678247.

Looking at the last two operations, artist 111 (the artist being merged into)
would indeed end up with two "ja" aliases having `primary_for_locale='t'`. This
is impossible according to our database constraints, though, so the packet must
not be representing what actually happened.

Looking more closely, the first alias with id 11 is actually having its
`primary_for_locale` being updated from false to true. But this is also
impossible: [our alias merge
code](https://github.com/metabrainz/musicbrainz-server/blob/ef48045/lib/MusicBrainz/Server/Data/Alias.pm#L186)
can only possibly set it from true to false. The only other way
`primary_for_locale` could be changed during a merge is through a
[`unique_primary_for_locale`
trigger](https://github.com/metabrainz/musicbrainz-server/blob/ef48045/admin/sql/CreateTriggers.sql#L55-L56)
which calls the [`unique_primary_artist_alias`
function](https://github.com/metabrainz/musicbrainz-server/blob/ef48045admin/sql/CreateFunctions.sql#L759-L769).
This function ensures that if we set `primary_for_locale='t'` on one alias, we
set it to false on all other aliases for that locale, preventing a constraint
violation. But this function can also only change `primary_for_locale` from
true to false.

At this point, I assumed the packet had these operations out of order. There
was evidence of that. In operation 2, the alias with `id` 11 has its artist
being changed from 222 to 111 (the artist being merged into). I knew this
because the key data contains the keys before the operation occurred. But
operation 1 right above it showed the same alias having its artist already set
to 111 in the keys. So it must be that operations 1 & 2 were swapped, given
what I know about our merge code, triggers, and how replication packets are
applied.

(As an aside, when applying an `UPDATE` from the packet, [we use all keys to
construct the WHERE
clause](https://github.com/metabrainz/musicbrainz-server/blob/ef48045/admin/replication/ProcessReplicationChanges#L313):
not just the primary keys (`id` in this case), but foreign keys too (`artist`).
dbmirror includes foreign keys when the "verbose" option is passed to the
`recordchange` procedure. MusicBrainz normally has verbose mode enabled,
including the one for `artist_alias`. This had the effect that since there was
no alias with id 11 and artist 111 at the time operation 1 was applied, `WHERE
id = 11 AND artist = 111` returned an empty set, causing the operation to be a
no-op. But that's beside the point; applying it out of order wouldn't have made
sense, and further, wouldn't have prevented the subsequent constraint
violation.)

Once I knew operations 1 & 2 were out of order, I tried to figure out why.
Earlier I noted that during an artist merge, only two spots can change
`primary_for_locale` to false: [the actual merge
code](https://github.com/metabrainz/musicbrainz-server/blob/ef48045/lib/MusicBrainz/Server/Data/Alias.pm#L186)
and [the `unique_primary_artist_alias`
function](https://github.com/metabrainz/musicbrainz-server/blob/ef48045/admin/sql/CreateFunctions.sql#L759-L769).
The merge code should prevent the SQL function from being run at all, but after
some investigation (i.e. replaying edit #45678247 locally and observing what
happens at each step), there was in fact [a bug that caused it to
run](https://github.com/metabrainz/musicbrainz-server/commit/a753b2d).
That shouldn't have been a problem, still, outside of befuddling dbmirror.

By adding some logging to the `unique_primary_artist_alias` function and
dbmirror, I was able see what order things were happening in. (dbmirror's
pending.c already has its own logging, enabled by uncommenting
`#define DEBUG_OUTPUT 1` and recompiling.)

```
--- a/admin/sql/CreateFunctions.sql
+++ b/admin/sql/CreateFunctions.sql
@@ -1078,9 +1078,17 @@ $$ LANGUAGE 'plpgsql';

 CREATE OR REPLACE FUNCTION unique_primary_artist_alias()
 RETURNS trigger AS $$
+DECLARE
+  to_update RECORD;
 BEGIN
+    RAISE NOTICE 'IN unique_primary_artist_alias; OLD: %, NEW: %', OLD, NEW;
     IF NEW.primary_for_locale THEN
-      UPDATE artist_alias SET primary_for_locale = FALSE
+      SELECT * FROM musicbrainz.artist_alias
+      WHERE locale = NEW.locale AND id != NEW.id
+        AND artist = NEW.artist
+      INTO to_update;
+      RAISE NOTICE 'IN unique_primary_artist_alias; UPDATING %', to_update;
+      UPDATE musicbrainz.artist_alias SET primary_for_locale = FALSE
       WHERE locale = NEW.locale AND id != NEW.id
         AND artist = NEW.artist;
     END IF;
```

Replaying edit #45678247, I got the following (edited again for clarity and
brevity):

```
NOTICE:  IN unique_primary_artist_alias; OLD: (1,222,CHACK,ja,t), NEW: (1,111,CHACK,ja,t)
NOTICE:  IN unique_primary_artist_alias; UPDATING (,,,,)
NOTICE:  IN unique_primary_artist_alias; OLD: (2,333,"栄喜",ja,t), NEW: (2,111,"栄喜",ja,t)
NOTICE:  IN unique_primary_artist_alias; UPDATING (1,111,CHACK,ja,t)
NOTICE:  IN unique_primary_artist_alias; OLD: (1,111,CHACK,ja,t), NEW: (1,111,CHACK,ja,f)
NOTICE:  dbmirror:packageData data block: ""id"='1' "artist"='111' "name"='CHACK' "locale"='ja' "primary_for_locale"='f' "
NOTICE:  dbmirror:packageData data block: ""id"='1' "artist"='111' "name"='CHACK' "locale"='ja' "primary_for_locale"='t' "
NOTICE:  dbmirror:packageData data block: ""id"='2' "artist"='111' "name"='栄喜' "locale"='ja' "primary_for_locale"='t' "
```

I noticed three things:

  1. The alias triggers all run together first, then all of the replication
     triggers do. This is because `unique_primary_for_locale` (UPFL) is
     defined to run `BEFORE` updates, and the replication triggers are
     defined to run `AFTER`.
  2. When `unique_primary_artist_alias` is invoked the second time for alias
     栄喜, it sees that CHACK already has `primary_for_locale`, and proceeds to
     unset it from there. Unsetting it causes the UPFL trigger to be invoked
     again. This is called [cascading triggers](https://www.postgresql.org/docs/9.5/trigger-definition.html). 
  3. The alias logging appears in the order we'd expect, and the first
     dbmirror statement corresponds to the last alias one (the cascaded one).

Point 3 got to the crux of the issue: when triggers are cascaded, any
`AFTER` triggers will run for the innermost statements first. dbmirror
shouldn't then trust the `NEW` row inside a trigger to represent the
"current" row. The `NEW` row is only a snapshot of the row-level operation at
the time it happens.

This issue became the motivation for writing dbmirror2. It tackles these
problems by detecting out-of-order operations, and reordering them as they
occur; see MasterSetup.sql for the implementation.
