\set ON_ERROR_STOP 1

BEGIN;

INSERT INTO foo.bar VALUES
	(:id_start + 1),
	(:id_start + 2),
	(:id_start + 3);

INSERT INTO foo.foo VALUES
	(:id_start + 1, :id_start + 1, 'bearable'),
	(:id_start + 2, :id_start + 2, 'circumpolar'),
	(:id_start + 3, :id_start + 3, 'colossi'),
	(:id_start + 4, :id_start + 1, 'fjord'),
	(:id_start + 5, :id_start + 2, 'humoring'),
	(:id_start + 6, :id_start + 3, 'nonetheless'),
	(:id_start + 7, :id_start + 1, 'erich'),
	(:id_start + 8, :id_start + 2, 'manumit'),
	(:id_start + 9, :id_start + 3, 'pensioner');

COMMIT;

BEGIN;

UPDATE foo.foo SET name = 'hospitable' WHERE id = (:id_start + 1);
UPDATE foo.foo SET name = 'solidification' WHERE id = (:id_start + 2);
UPDATE foo.foo SET name = 'parent' WHERE id = (:id_start + 3);
UPDATE foo.foo SET name = 'decimation' WHERE id = (:id_start + 4);
UPDATE foo.foo SET name = 'verandah' WHERE id = (:id_start + 5);
UPDATE foo.foo SET name = 'people' WHERE id = (:id_start + 6);
UPDATE foo.foo SET name = 'annuli' WHERE id = (:id_start + 7);
UPDATE foo.foo SET name = 'whirls' WHERE id = (:id_start + 8);
UPDATE foo.foo SET name = 'platoon' WHERE id = (:id_start + 9);

COMMIT;

BEGIN;

UPDATE foo.bar SET id = (:id_start + 4) WHERE id = (:id_start + 1);
UPDATE foo.bar SET id = (:id_start + 5) WHERE id = (:id_start + 2);
UPDATE foo.bar SET id = (:id_start + 6) WHERE id = (:id_start + 3);

COMMIT;

BEGIN;

DELETE FROM foo.foo WHERE bar = (:id_start + 4);
DELETE FROM foo.bar WHERE id = (:id_start + 5);

COMMIT;
