CREATE TABLE editor (id INTEGER, name TEXT, password TEXT);
ALTER TABLE editor ADD CONSTRAINT editor_pkey PRIMARY KEY (id);

CREATE FUNCTION sanitize_editor(e editor)
RETURNS editor
LANGUAGE sql
STABLE
STRICT
PARALLEL SAFE
AS $$ SELECT ROW(e.id, e.name, NULL::TEXT)::editor $$;

CREATE OR REPLACE FUNCTION sanitize_dbmirror2_editor()
RETURNS trigger AS $$
BEGIN
    NEW.olddata = row_to_json(sanitize_editor(json_populate_record(NULL::editor, NEW.olddata)));
    NEW.newdata = row_to_json(sanitize_editor(json_populate_record(NULL::editor, NEW.newdata)));
    IF NEW.op = 'u' AND NEW.olddata::JSONB = NEW.newdata::JSONB THEN
        -- Only sanitized columns have changed. No need to log the update.
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
