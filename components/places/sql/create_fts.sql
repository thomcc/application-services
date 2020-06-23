-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- This is separate from create_shared_schema.sql so that it can be used when
-- migrating too. We also totally wipe and reindex if this code gets run, which
-- is unfortunate, but the `unicode61` tokenizer is fast enough that it doesn't
-- matter much. If our migration strategy were better/more fine-grained, this
-- wouldn't be necessary. So it goes.

-- XXX might not be needed anymore?

-- Wipe any existing record of the FTS table
DROP TRIGGER IF EXISTS moz_places_fts_after_insert;
DROP TRIGGER IF EXISTS moz_places_fts_after_update;
DROP TRIGGER IF EXISTS moz_places_fts_after_delete;
DROP TABLE IF EXISTS moz_places_fts;

-- Re-define it.
CREATE VIRTUAL TABLE moz_places_fts USING fts5(
    url,
    title,
    -- TODO: custom tokenizer, requires
    -- https://github.com/jgallagher/rusqlite/issues/689.
    tokenize=unicode61,
    content='moz_places',
    content_rowid='id'
);

-- Note: these are not temp triggers, so they don't go with the trigger code!
-- Changing these requires schema update, although since they're taken directly
-- from the SQLite docs, they probably don't need updating with much urgency.
-- See https://www.sqlite.org/fts5.html#external_content_tables
CREATE TRIGGER moz_places_fts_after_insert AFTER INSERT ON moz_places BEGIN
    -- Forward inserts to the FTS table
    INSERT INTO moz_places_fts(rowid, url, title) VALUES (new.id, new.url, new.title);
END;

CREATE TRIGGER moz_places_fts_after_delete AFTER DELETE ON moz_places BEGIN
    -- Forward deletes to the FTS table
    INSERT INTO moz_places_fts(moz_places_fts, rowid, url, title)
        VALUES('delete', old.id, old.url, old.title);
END;

CREATE TRIGGER moz_places_fts_after_update AFTER UPDATE ON moz_places BEGIN
    -- Updates are just insert/delete combinations.
    INSERT INTO moz_places_fts(moz_places_fts, rowid, url, title)
        VALUES('delete', old.id, old.url, old.title);
    INSERT INTO moz_places_fts(rowid, url, title) VALUES (new.id, new.url, new.title);
END;

-- Insert anything in the existing places table into the FTS table.
INSERT INTO moz_places_fts(rowid, url, title)
SELECT id, url, title FROM moz_places;
