CREATE SCHEMA musicbrainz;

SET search_path = musicbrainz, public;

CREATE TABLE artist (
    id SERIAL
);

ALTER TABLE artist ADD CONSTRAINT artist_pkey PRIMARY KEY (id);

CREATE TABLE artist_alias (
    id SERIAL,
    artist INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    locale TEXT,
    primary_for_locale BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE artist_alias ADD CONSTRAINT artist_alias_pkey PRIMARY KEY (id);

ALTER TABLE artist_alias
   ADD CONSTRAINT artist_alias_fk_artist
   FOREIGN KEY (artist)
   REFERENCES artist(id);

CREATE UNIQUE INDEX artist_alias_idx_primary ON artist_alias (artist, locale)
    WHERE primary_for_locale = TRUE AND locale IS NOT NULL;

CREATE OR REPLACE FUNCTION unique_primary_artist_alias()
RETURNS trigger AS $$
BEGIN
    IF NEW.primary_for_locale THEN
      UPDATE musicbrainz.artist_alias SET primary_for_locale = FALSE
      WHERE locale = NEW.locale AND id != NEW.id
        AND artist = NEW.artist;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION delete_new_row()
RETURNS trigger AS $$
BEGIN
    DELETE FROM artist_alias WHERE id = NEW.id;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';
