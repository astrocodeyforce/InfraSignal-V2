BEGIN;

-- Per-body priority zone overrides.
-- body_id NULL  = global default zone config (managed by superusers).
-- body_id set   = that body's override of the same osm_key/osm_value zone,
--                 managed by the body's own staff in the scoped admin.
ALTER TABLE priority_zone_config
    ADD COLUMN body_id integer REFERENCES body(id) ON DELETE CASCADE;

-- Replace the global unique constraint: uniqueness is now per scope.
ALTER TABLE priority_zone_config
    DROP CONSTRAINT priority_zone_config_osm_key_osm_value_key;

CREATE UNIQUE INDEX priority_zone_config_global_key
    ON priority_zone_config (osm_key, osm_value)
    WHERE body_id IS NULL;

CREATE UNIQUE INDEX priority_zone_config_body_key
    ON priority_zone_config (osm_key, osm_value, body_id)
    WHERE body_id IS NOT NULL;

COMMIT;
