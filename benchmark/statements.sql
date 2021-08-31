\set ON_ERROR_STOP 1

BEGIN;

INSERT INTO foo.bar VALUES (1), (2), (3);

INSERT INTO foo.foo VALUES
	(1, 1, 'bearable'),
	(2, 2, 'circumpolar'),
	(3, 1, 'colossi'),
	(4, 2, 'fjord'),
	(5, 1, 'humoring'),
	(6, 2, 'nonetheless'),
	(7, 1, 'erich'),
	(8, 2, 'manumit'),
	(9, 1, 'pensioner');

COMMIT;

BEGIN;

UPDATE foo.foo SET name = 'hospitable' WHERE id = 1;
UPDATE foo.foo SET name = 'solidification' WHERE id = 2;
UPDATE foo.foo SET name = 'parent' WHERE id = 3;
UPDATE foo.foo SET name = 'decimation' WHERE id = 4;
UPDATE foo.foo SET name = 'verandah' WHERE id = 5;
UPDATE foo.foo SET name = 'people' WHERE id = 6;
UPDATE foo.foo SET name = 'annuli' WHERE id = 7;
UPDATE foo.foo SET name = 'whirls' WHERE id = 8;
UPDATE foo.foo SET name = 'platoon' WHERE id = 9;

COMMIT;

BEGIN;

UPDATE foo.foo SET id = id + 10;
UPDATE foo.bar SET id = id + 10;
UPDATE foo.foo SET bar = NULL WHERE bar = 12;

COMMIT;

BEGIN;

DELETE FROM foo.foo WHERE bar = 11;
DELETE FROM foo.foo WHERE bar = 12;
DELETE FROM foo.foo WHERE bar IS NULL;
DELETE FROM foo.bar;

COMMIT;
