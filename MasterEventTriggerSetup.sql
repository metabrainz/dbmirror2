-- Defines an event trigger that refreshes `dbmirror2.column_info`
-- whenever the schema is modified. Alternatively, you can refresh the
-- view manually during schema changes. (That is preferred to avoid
-- refreshing it multiple times in a single upgrade script.)
--
-- This file must be executed by a superuser.

BEGIN;

CREATE FUNCTION dbmirror2.refresh_column_info()
RETURNS event_trigger AS $$
BEGIN
    REFRESH MATERIALIZED VIEW dbmirror2.column_info;
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER refresh_column_info
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE', 'DROP TABLE')
    EXECUTE PROCEDURE dbmirror2.refresh_column_info();

COMMIT;
