CREATE SCHEMA foo;

CREATE TABLE foo.foo (
    id SERIAL,
    bar INTEGER,
    name TEXT,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE foo.bar (
    id INTEGER
);

ALTER TABLE foo.foo ADD CONSTRAINT foo_pkey PRIMARY KEY (id);

ALTER TABLE foo.bar ADD CONSTRAINT bar_pkey PRIMARY KEY (id);

ALTER TABLE foo.foo
   ADD CONSTRAINT foo_fk_bar
   FOREIGN KEY (bar)
   REFERENCES foo.bar(id)
   ON DELETE CASCADE
   ON UPDATE CASCADE;

CREATE OR REPLACE FUNCTION b_upd_last_updated_table() RETURNS trigger AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER b_upd_foo BEFORE UPDATE ON foo.foo
    FOR EACH ROW EXECUTE PROCEDURE b_upd_last_updated_table();
