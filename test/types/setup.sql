CREATE TRIGGER "reptg2_📜"
AFTER INSERT OR DELETE OR UPDATE ON "📜"
FOR EACH ROW EXECUTE PROCEDURE dbmirror2.recordchange();

INSERT INTO "📜" VALUES (
    'a',
    998877665544332211,
    true,
    E'\\xABC123',
    'foo',
    'a',
    '(1,2,3)',
    '2026-05-06',
    123,
    ARRAY[1, 2, 3],
    '{"key":"foo"}',
    '{"key":"foo"}',
    'a',
    '(1.0, 2.0)',
    100,
    ARRAY[10, 20],
    'foo',
    ARRAY['foo'],
    '2026-05-06 12:00:00+00',
    '6d2d7b41-c929-4a2a-8492-f01af7ebc8ae'
);

UPDATE "📜"
   SET "bigint"                    = 112233445566778899,
       "boolean"                   = false,
       "bytea"                     = E'\\xDEADBEEF',
       "character varying"         = 'bar',
       "character(1)"              = 'b',
       "cube"                      = '(4,5,6)',
       "date"                      = '2026-05-07',
       "integer"                   = 456,
       "integer[]"                 = ARRAY[4, 5, 6],
       "json"                      = '{"key":"bar"}',
       "jsonb"                     = '{"key":"bar"}',
       "kustom_enum"               = 'b',
       "point"                     = '(3.0, 4.0)',
       "smallint"                  = 200,
       "smallint[]"                = ARRAY[30, 40],
       "text"                      = 'bar',
       "text[]"                    = ARRAY['bar'],
       "timestamp with time zone"  = '2026-05-07 12:00:00+00',
       "uuid"                      = '790fa38b-ad50-47bf-ab2a-e5f2702e00f2'
 WHERE """char""" = 'a';

DROP TRIGGER "reptg2_📜" ON "📜";

TRUNCATE "📜";
