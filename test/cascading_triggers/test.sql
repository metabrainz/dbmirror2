BEGIN;

SET search_path = musicbrainz, public;

SELECT plan(12);

SELECT is((SELECT artist FROM artist_alias WHERE id = 1), 10);
SELECT is((SELECT locale FROM artist_alias WHERE id = 1), 'ja');
SELECT is((SELECT name FROM artist_alias WHERE id = 1), 'CHACK');
SELECT is((SELECT primary_for_locale FROM artist_alias WHERE id = 1), 'f');

SELECT is((SELECT artist FROM artist_alias WHERE id = 2), 10);
SELECT is((SELECT locale FROM artist_alias WHERE id = 2), 'ja');
SELECT is((SELECT name FROM artist_alias WHERE id = 2), '栄喜');
SELECT is((SELECT primary_for_locale FROM artist_alias WHERE id = 2), 'f');

SELECT is((SELECT artist FROM artist_alias WHERE id = 3), 10);
SELECT is((SELECT locale FROM artist_alias WHERE id = 3), 'ja');
SELECT is((SELECT name FROM artist_alias WHERE id = 3), 'test');
SELECT is((SELECT primary_for_locale FROM artist_alias WHERE id = 3), 't');

SELECT * FROM finish();

ROLLBACK;
