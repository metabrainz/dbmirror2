CREATE TYPE kustom_enum AS ENUM ('a', 'b', 'c');

CREATE TABLE "📜" (
    """char"""                  "char" PRIMARY KEY,
    "bigint"                    bigint,
    "boolean"                   boolean,
    "bytea"                     bytea,
    "character varying"         character varying,
    "character(1)"              character(1),
    "cube"                      cube,
    "date"                      date,
    "integer"                   integer,
    "integer[]"                 integer[],
    "json"                      json,
    "jsonb"                     jsonb,
    "kustom_enum"               kustom_enum,
    "point"                     point,
    "smallint"                  smallint,
    "smallint[]"                smallint[],
    "text"                      text,
    "text[]"                    text[],
    "timestamp with time zone"  timestamp with time zone,
    "uuid"                      uuid
);
