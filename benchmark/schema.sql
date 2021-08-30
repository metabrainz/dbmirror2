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
   REFERENCES foo.bar(id);
