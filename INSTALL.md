Installation on the master is done by hand. In the MusicBrainz production DB,
we have a `musicbrainz` user which owns most of our schemas. `postgres` is
the superuser.

```sh
DB=musicbrainz_db
PGUSER=musicbrainz
PGSUPERUSER=postgres

# Specify connection parameters as needed.

psql -c "CREATE SCHEMA dbmirror2 AUTHORIZATION $PGUSER" $DB $PGSUPERUSER

psql -f ReplicationSetup.sql $DB $PGUSER
psql -f MasterSetup.sql $DB $PGUSER

# Creates an EVENT TRIGGER, which must be done as a superuser.
psql -f SuperuserMasterSetup.sql $DB $PGSUPERUSER
```
