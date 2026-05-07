INSERT INTO editor
VALUES (1, 'foo', NULL), (2, 'bar', NULL);

CREATE TRIGGER reptg2_editor
AFTER INSERT OR DELETE OR UPDATE ON editor
FOR EACH ROW EXECUTE PROCEDURE dbmirror2.recordchange();

CREATE TRIGGER sanitize_dbmirror2_editor
BEFORE INSERT ON dbmirror2.pending_data
FOR EACH ROW
WHEN (NEW.tablename = 'musicbrainz.editor')
EXECUTE PROCEDURE sanitize_dbmirror2_editor();

UPDATE editor SET password = '123' WHERE id = 1;
DELETE FROM editor WHERE id = 2;
INSERT INTO editor VALUES (3, 'baz', '456');

DROP TRIGGER reptg2_editor ON editor;

TRUNCATE editor;

-- Add back the initial data so we can replay the logged changes against it.
INSERT INTO editor
VALUES (1, 'foo', NULL), (2, 'bar', NULL);
