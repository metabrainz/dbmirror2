SET search_path = musicbrainz, public;

INSERT INTO artist (id) VALUES (10), (20), (30), (40);

INSERT INTO artist_alias (artist, id, locale, name, primary_for_locale)
VALUES (20, 1, 'ja', 'CHACK', '1'),
       (30, 2, 'ja', '栄喜', '1'),
       (40, 3, 'ja', 'test', '1');

CREATE TRIGGER reptg2_artist_alias
AFTER INSERT OR DELETE OR UPDATE ON artist_alias
FOR EACH ROW EXECUTE PROCEDURE dbmirror2.recordchange();

CREATE TRIGGER unique_primary_for_locale
BEFORE UPDATE OR INSERT ON artist_alias
FOR EACH ROW EXECUTE PROCEDURE unique_primary_artist_alias();

CREATE TRIGGER delete_new_row
AFTER INSERT ON artist_alias
FOR EACH ROW EXECUTE PROCEDURE delete_new_row();

UPDATE artist_alias SET artist = 10;

INSERT INTO artist_alias (artist, id, locale, name, primary_for_locale)
VALUES (20, 4, 'ja', 'DELETEME', '0');

DROP TRIGGER delete_new_row ON artist_alias;

INSERT INTO artist_alias (artist, id, locale, name, primary_for_locale)
VALUES (20, 4, 'ja', 'DELETEME', '0');

CREATE TRIGGER delete_updated_row
AFTER UPDATE ON artist_alias
FOR EACH ROW EXECUTE PROCEDURE delete_new_row();

UPDATE artist_alias SET id = 5 WHERE id = 4;

DROP TRIGGER reptg2_artist_alias ON artist_alias;
DROP TRIGGER unique_primary_for_locale ON artist_alias;
DROP TRIGGER delete_updated_row ON artist_alias;

TRUNCATE artist_alias;

-- Add back the initial data so we can replay the logged changes against it.
INSERT INTO artist_alias (artist, id, locale, name, primary_for_locale)
VALUES (20, 1, 'ja', 'CHACK', '1'),
       (30, 2, 'ja', '栄喜', '1'),
       (40, 3, 'ja', 'test', '1');
