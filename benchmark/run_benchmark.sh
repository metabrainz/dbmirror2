#!/usr/bin/env bash

SUPERUSER="${1:-postgres}"

cd "$(dirname "${BASH_SOURCE[0]}")/../"

dropdb -U "$SUPERUSER" old_dbmirror_test 2> /dev/null
createdb -O musicbrainz -U "$SUPERUSER" old_dbmirror_test

dropdb -U "$SUPERUSER" new_dbmirror_test 2> /dev/null
createdb -O musicbrainz -U "$SUPERUSER" new_dbmirror_test

set -e

psql -q -c 'CREATE FUNCTION recordchange() RETURNS trigger AS '\''$libdir/pending'\'', '\''recordchange'\'' LANGUAGE C' old_dbmirror_test "$SUPERUSER"
psql -q -c 'CREATE SCHEMA musicbrainz AUTHORIZATION musicbrainz' old_dbmirror_test "$SUPERUSER"
psql -q -f benchmark/OldReplicationSetup.sql old_dbmirror_test musicbrainz
psql -q -c 'CREATE SCHEMA dbmirror2 AUTHORIZATION musicbrainz' new_dbmirror_test "$SUPERUSER"
psql -q -f ReplicationSetup.sql new_dbmirror_test musicbrainz
psql -q -f MasterSetup.sql new_dbmirror_test musicbrainz
psql -q -f MasterEventTriggerSetup.sql new_dbmirror_test "$SUPERUSER"

psql -q -f benchmark/schema.sql old_dbmirror_test musicbrainz
psql -q -f benchmark/schema.sql new_dbmirror_test musicbrainz

trigger_sql=''
trigger_sql+='CREATE TRIGGER reptg_foo '
trigger_sql+='AFTER INSERT OR UPDATE OR DELETE ON foo.foo '
trigger_sql+='FOR EACH ROW EXECUTE PROCEDURE'

psql -q -c "$trigger_sql public.recordchange('verbose');" old_dbmirror_test musicbrainz
psql -q -c "$trigger_sql dbmirror2.recordchange();" new_dbmirror_test musicbrainz

echo 'Old (dbmirror):'
time {
    seq 0 100 49900 | parallel psql -q -v id_start={} -f benchmark/statements.sql old_dbmirror_test musicbrainz
}

echo
echo 'New (dbmirror2):'
time {
    seq 0 100 49900 | parallel psql -q -v id_start={} -f benchmark/statements.sql new_dbmirror_test musicbrainz
}
