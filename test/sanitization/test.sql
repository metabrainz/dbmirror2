BEGIN;

SET search_path = musicbrainz, public;

SELECT plan(3);

SELECT is((SELECT password FROM editor WHERE id = 1), NULL);
SELECT is((SELECT EXISTS (SELECT 1 FROM editor WHERE id = 2)), FALSE);
SELECT is((SELECT password FROM editor WHERE id = 3), NULL);

SELECT * FROM finish();

ROLLBACK;
