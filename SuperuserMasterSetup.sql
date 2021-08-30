-- This file must be executed by a superuser.

BEGIN;

SET search_path = dbmirror2, public;

CREATE EVENT TRIGGER refresh_column_info
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE', 'ALTER TABLE', 'DROP TABLE')
    EXECUTE PROCEDURE dbmirror2.refresh_column_info();

COMMIT;
