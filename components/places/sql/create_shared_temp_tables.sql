-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- This file defines temp tables shared between the main and Sync connections.

-- This table is used, along with moz_places_afterinsert_trigger, to update
-- origins after places removals. During an INSERT into moz_places, origins are
-- accumulated in this table, then a DELETE FROM moz_updateoriginsinsert_temp
-- will take care of updating the moz_origins table for every new origin. See
-- CREATE_PLACES_AFTERINSERT_TRIGGER_ORIGINS below for details.
CREATE TEMP TABLE moz_updateoriginsinsert_temp (
    place_id INTEGER PRIMARY KEY,
    prefix TEXT NOT NULL,
    host TEXT NOT NULL,
    rev_host TEXT NOT NULL,
    frecency INTEGER NOT NULL
);



-- This table is used (along with moz_updateoriginsupdate_temp) in a similar way
-- to moz_updateoriginsinsert_temp, but for deletes, and triggered via
-- moz_places_afterdelete_trigger.
--
-- When rows are added to this table, moz_places.origin_id may be null.  That's
-- why this table uses prefix + host as its primary key, not origin_id.
CREATE TEMP TABLE moz_updateoriginsdelete_temp (
    prefix TEXT NOT NULL,
    host TEXT NOT NULL,
    frecency_delta INTEGER NOT NULL,
    PRIMARY KEY (prefix, host)
) WITHOUT ROWID;

-- This table is used (along with moz_updateoriginsdelete_temp) in a similar way
-- to moz_updateoriginsinsert_temp, but for updates to places' frecencies, and
-- triggered via moz_places_afterupdate_frecency_trigger.
--
-- When rows are added to this table, moz_places.origin_id may be null.  That's
-- why this table uses prefix + host as its primary key, not origin_id.
CREATE TEMP TABLE moz_updateoriginsupdate_temp (
    prefix TEXT NOT NULL,
    host TEXT NOT NULL,
    frecency_delta INTEGER NOT NULL,
    PRIMARY KEY (prefix, host)
) WITHOUT ROWID;

-- Tags
CREATE TEMP TRIGGER moz_tags_relations_afterinsert_trigger
AFTER INSERT ON moz_tags_relation
BEGIN
    UPDATE moz_tags SET
        lastModified = now()
    WHERE id = NEW.tag_id;

    -- Tagging a URL increased the foreign count so that it will not be
    -- expired or otherwise automatically removed.
    UPDATE moz_places SET
        foreign_count = foreign_count + 1
    WHERE id = NEW.place_id;
END;

CREATE TEMP TRIGGER moz_tags_relations_afterupdate_trigger
AFTER UPDATE ON moz_tags_relation
BEGIN
    UPDATE moz_tags SET
        lastModified = now()
    WHERE id IN (OLD.tag_id, NEW.tag_id);

    UPDATE moz_places SET
        foreign_count = foreign_count + 1
    WHERE id = NEW.place_id;

    UPDATE moz_places SET
        foreign_count = foreign_count - 1
    WHERE id = OLD.place_id;
END;

CREATE TEMP TRIGGER moz_tags_relations_afterdelete_trigger
AFTER DELETE ON moz_tags_relation
BEGIN
    UPDATE moz_tags SET
        lastModified = now()
    WHERE id = OLD.tag_id;

    UPDATE moz_places SET
        foreign_count = foreign_count - 1
    WHERE id = OLD.place_id;
END;
