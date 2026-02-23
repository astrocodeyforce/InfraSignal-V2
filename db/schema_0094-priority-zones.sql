-- Schema migration 0094: OSM-based Priority Zone Classification
-- Creates tables for zone configuration and OSM data caching,
-- and adds OSM classification columns to the problem table.

BEGIN;

-- 1. Priority zone configuration table
-- Stores which OSM zone types map to which priority level
CREATE TABLE priority_zone_config (
    id              SERIAL PRIMARY KEY,
    osm_key         TEXT NOT NULL,           -- e.g. 'amenity', 'building', 'landuse'
    osm_value       TEXT NOT NULL,           -- e.g. 'hospital', 'school', 'residential'
    priority_level  TEXT NOT NULL DEFAULT 'Standard',  -- Emergency, High, Normal, Low
    radius_m        INTEGER NOT NULL DEFAULT 250,      -- detection radius in metres
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    label           TEXT,                    -- human-readable name, e.g. "Hospital"
    created         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(osm_key, osm_value)
);

-- 2. OSM zone cache table
-- Caches Overpass API results to avoid repeated lookups
CREATE TABLE osm_zone_cache (
    id              SERIAL PRIMARY KEY,
    latitude        NUMERIC(10,7) NOT NULL,
    longitude       NUMERIC(10,7) NOT NULL,
    radius_m        INTEGER NOT NULL DEFAULT 500,
    osm_data        JSONB,                   -- raw Overpass elements
    fetched_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at      TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

-- Index for fast geo+radius lookups on cache
CREATE INDEX idx_osm_zone_cache_geo ON osm_zone_cache (latitude, longitude, radius_m);

-- Index for cache expiry cleanup
CREATE INDEX idx_osm_zone_cache_expires ON osm_zone_cache (expires_at);

-- 3. Add OSM classification columns to problem table
-- These store the result of auto-classification
ALTER TABLE problem ADD COLUMN osm_zone_priority TEXT;          -- matched priority level
ALTER TABLE problem ADD COLUMN osm_zone_label TEXT;             -- matched zone label
ALTER TABLE problem ADD COLUMN osm_zone_classified_at TIMESTAMP;-- when classification ran
ALTER TABLE problem ADD COLUMN osm_zone_distance_m NUMERIC(8,1);-- distance to nearest zone
ALTER TABLE problem ADD COLUMN osm_zone_admin_override BOOLEAN NOT NULL DEFAULT FALSE; -- admin manually overrode

-- Index for filtering/reporting by zone priority
CREATE INDEX idx_problem_osm_zone_priority ON problem (osm_zone_priority) WHERE osm_zone_priority IS NOT NULL;

COMMIT;
