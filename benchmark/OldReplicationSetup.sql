\set ON_ERROR_STOP 1

SET search_path = musicbrainz;

BEGIN;

CREATE AGGREGATE array_cat_agg(int2[]) (
    sfunc       = array_cat,
    stype       = int2[],
    initcond    = '{}'
);

CREATE TABLE dbmirror_pending (
    seqid       SERIAL,
    tablename   VARCHAR NOT NULL,
    op          CHARACTER,
    xid         INTEGER NOT NULL,
    PRIMARY KEY (seqid)
);

CREATE INDEX dbmirror_pending_xid_index ON dbmirror_pending (xid);

CREATE TABLE dbmirror_pendingdata (
    seqid       INTEGER NOT NULL,
    IsKey       BOOL NOT NULL,
    Data        VARCHAR,
    PRIMARY KEY (seqid, iskey),
    FOREIGN KEY (seqid)
        REFERENCES dbmirror_pending (seqid)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMIT;
