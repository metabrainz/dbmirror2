#!/bin/bash

SUPERUSER="${1:-postgres}"
DB=dbmirror2_test
RECORD_PENDING_DATA="${RECORD_PENDING_DATA:-0}"

dropdb --username="$SUPERUSER" $DB 2> /dev/null
createdb --username="$SUPERUSER" --owner musicbrainz $DB
psql -c 'CREATE SCHEMA musicbrainz;' $DB musicbrainz
psql -c 'ALTER DATABASE dbmirror2_test SET search_path TO musicbrainz, public' $DB "$SUPERUSER"
psql -c 'ALTER DATABASE dbmirror2_test SET timezone TO '\''UTC'\''' $DB "$SUPERUSER"
psql -c 'CREATE EXTENSION cube' $DB musicbrainz
psql -c 'CREATE EXTENSION pgtap' $DB "$SUPERUSER"
psql -c 'CREATE SCHEMA dbmirror2 AUTHORIZATION musicbrainz' $DB "$SUPERUSER"
psql -f ReplicationSetup.sql $DB musicbrainz
psql -f dbmirror2.sql $DB musicbrainz

for test in test/*; do
    psql -f "$test/schema.sql" $DB musicbrainz
done

# When recording/comparing the expected `dbmirror2.pending_*` rows,
# we normalize the `seqid` and `xid` values so that they always start
# at 1. The `ts` column is also normalized such that each distinct
# timestamp is replaced with a value that is 1 minute greater than the
# previous one, starting from the UNIX epoch.

read -r -d '' PENDING_DATA_QUERY << SQL
SELECT (seqid - min(seqid) OVER ()) + 1 AS seqid,
       op,
       (xid - min(xid) OVER ()) + 1 AS xid,
       olddata,
       newdata,
       trgdepth
  FROM dbmirror2.pending_data
 ORDER BY seqid
SQL

read -r -d '' PENDING_TS_QUERY << SQL
SELECT (xid - min(xid) OVER ()) + 1 AS xid,
       timestamp '1970-01-01' + ((dense_rank() OVER (ORDER BY ts) - 1) * interval '1 minute') AS ts
  FROM dbmirror2.pending_ts
 ORDER BY xid
SQL

for test in test/*; do
    psql -f "$test/setup.sql" $DB musicbrainz

    PENDING_DATA="$(psql -P pager=off -x -c "$PENDING_DATA_QUERY" $DB musicbrainz)"
    PENDING_TS="$(psql -P pager=off -x -c "$PENDING_TS_QUERY" $DB musicbrainz)"
    if [[ "$RECORD_PENDING_DATA" = '1' ]]; then
        mkdir -p "$test/expected"
        echo "$PENDING_DATA" > "$test/expected/pending_data.txt"
        echo "$PENDING_TS" > "$test/expected/pending_ts.txt"
    else
        DIFF=$(diff <(echo "$PENDING_DATA") <(cat "$test/expected/pending_data.txt"))
        if [[ $? -ne 0 ]]; then
            echo "Expected pending_data differs for $test:"
            echo "$DIFF"
            exit 1
        fi
        DIFF=$(diff <(echo "$PENDING_TS") <(cat "$test/expected/pending_ts.txt"))
        if [[ $? -ne 0 ]]; then
            echo "Expected pending_ts differs for $test:"
            echo "$DIFF"
            exit 1
        fi
    fi
    ./DBMirror.pl --database $DB --username musicbrainz
    psql -c 'TRUNCATE dbmirror2.pending_data' $DB musicbrainz
    psql -c 'TRUNCATE dbmirror2.pending_ts' $DB musicbrainz
done

pg_prove --dbname $DB --username=musicbrainz test/*/test.sql
