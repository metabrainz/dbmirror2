#!/bin/bash

SUPERUSER="${1:-postgres}"
DB=dbmirror2_test

dropdb --username="$SUPERUSER" $DB 2> /dev/null
createdb --username="$SUPERUSER" --owner musicbrainz $DB
psql -c 'CREATE EXTENSION pgtap' $DB "$SUPERUSER"
psql -c 'CREATE SCHEMA dbmirror2 AUTHORIZATION musicbrainz' $DB "$SUPERUSER"
psql -f ReplicationSetup.sql $DB musicbrainz
psql -f MasterSetup.sql $DB musicbrainz
psql -f SuperuserMasterSetup.sql $DB "$SUPERUSER"

for test in test/*; do
    psql -f "$test/schema.sql" $DB musicbrainz
done

for test in test/*; do
    psql -f "$test/setup.sql" $DB musicbrainz
    psql -P pager=off -x -c 'SELECT * FROM dbmirror2.pending_data ORDER BY seqid' $DB musicbrainz
    ./DBMirror.pl --database $DB --username musicbrainz
    psql -c 'TRUNCATE dbmirror2.pending_data' $DB musicbrainz
    psql -c 'TRUNCATE dbmirror2.pending_keys' $DB musicbrainz
    psql -c 'TRUNCATE dbmirror2.pending_xid_timestamp' $DB musicbrainz
done

pg_prove --dbname $DB --username=musicbrainz test/*/test.sql
