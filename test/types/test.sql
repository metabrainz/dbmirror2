BEGIN;

SELECT plan(19);

-- Tests that various different types can be replicated correctly.

SELECT is((SELECT "bigint"                      FROM "📜" WHERE """char""" = 'a'), 112233445566778899::bigint);
SELECT is((SELECT "boolean"                     FROM "📜" WHERE """char""" = 'a'), false);
SELECT is((SELECT "bytea"                       FROM "📜" WHERE """char""" = 'a'), E'\\xDEADBEEF'::bytea);
SELECT is((SELECT "character varying"           FROM "📜" WHERE """char""" = 'a'), 'bar');
SELECT is((SELECT "character(1)"                FROM "📜" WHERE """char""" = 'a'), 'b');
SELECT is((SELECT "cube"                        FROM "📜" WHERE """char""" = 'a'), '(4,5,6)'::cube);
SELECT is((SELECT "date"                        FROM "📜" WHERE """char""" = 'a'), '2026-05-07'::date);
SELECT is((SELECT "integer"                     FROM "📜" WHERE """char""" = 'a'), 456::integer);
SELECT is((SELECT "integer[]"                   FROM "📜" WHERE """char""" = 'a'), ARRAY[4, 5, 6]::integer[]);
SELECT is((SELECT "json"::text                  FROM "📜" WHERE """char""" = 'a'), '{"key":"bar"}');
SELECT is((SELECT "jsonb"                       FROM "📜" WHERE """char""" = 'a'), '{"key":"bar"}'::jsonb);
SELECT is((SELECT "kustom_enum"                 FROM "📜" WHERE """char""" = 'a'), 'b'::kustom_enum);
SELECT is((SELECT "point"::text                 FROM "📜" WHERE """char""" = 'a'), '(3,4)');
SELECT is((SELECT "smallint"                    FROM "📜" WHERE """char""" = 'a'), 200::smallint);
SELECT is((SELECT "smallint[]"                  FROM "📜" WHERE """char""" = 'a'), ARRAY[30, 40]::smallint[]);
SELECT is((SELECT "text"                        FROM "📜" WHERE """char""" = 'a'), 'bar');
SELECT is((SELECT "text[]"                      FROM "📜" WHERE """char""" = 'a'), ARRAY['bar']::text[]);
SELECT is((SELECT "timestamp with time zone"    FROM "📜" WHERE """char""" = 'a'), '2026-05-07 12:00:00+00'::timestamptz);
SELECT is((SELECT "uuid"                        FROM "📜" WHERE """char""" = 'a'), '790fa38b-ad50-47bf-ab2a-e5f2702e00f2'::uuid);

SELECT * FROM finish();

ROLLBACK;
