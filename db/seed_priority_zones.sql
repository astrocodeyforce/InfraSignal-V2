-- Seed data for priority_zone_config
-- 30 OSM zone types classified into 4 priority levels
-- Maps to existing response_priorities: Emergency, High, Normal, Low

BEGIN;

-- ============================================
-- CRITICAL → maps to "Emergency" priority
-- ============================================
INSERT INTO priority_zone_config (osm_key, osm_value, priority_level, radius_m, label) VALUES
('amenity', 'hospital',        'Emergency', 250, 'Hospital'),
('amenity', 'school',          'Emergency', 250, 'School'),
('amenity', 'kindergarten',    'Emergency', 250, 'Kindergarten / Daycare'),
('building', 'hospital',      'Emergency', 250, 'Hospital Building'),
('building', 'school',        'Emergency', 250, 'School Building'),
('amenity', 'fire_station',   'Emergency', 250, 'Fire Station');

-- ============================================
-- HIGH → maps to "High" priority
-- ============================================
INSERT INTO priority_zone_config (osm_key, osm_value, priority_level, radius_m, label) VALUES
('amenity', 'police',          'High', 250, 'Police Station'),
('amenity', 'clinic',          'High', 250, 'Medical Clinic'),
('amenity', 'nursing_home',    'High', 250, 'Nursing Home'),
('amenity', 'childcare',       'High', 250, 'Childcare Center'),
('amenity', 'university',      'High', 250, 'University'),
('amenity', 'college',         'High', 250, 'College'),
('amenity', 'community_centre','High', 250, 'Community Center'),
('amenity', 'library',         'High', 250, 'Library'),
('amenity', 'bus_station',     'High', 250, 'Bus Station'),
('building', 'train_station',  'High', 250, 'Train Station'),
('amenity', 'place_of_worship','High', 250, 'Place of Worship'),
('amenity', 'social_facility', 'High', 250, 'Social Facility'),
('amenity', 'shelter',         'High', 250, 'Shelter'),
('leisure', 'playground',      'High', 250, 'Playground'),
('tourism', 'museum',          'High', 250, 'Museum'),
('amenity', 'marketplace',     'High', 250, 'Marketplace'),
('highway', 'bus_stop',        'High', 200, 'Bus Stop');

-- ============================================
-- MEDIUM → maps to "Normal" priority
-- ============================================
INSERT INTO priority_zone_config (osm_key, osm_value, priority_level, radius_m, label) VALUES
('leisure', 'park',            'Normal', 250, 'Public Park'),
('leisure', 'sports_centre',   'Normal', 250, 'Sports Center'),
('leisure', 'swimming_pool',   'Normal', 250, 'Swimming Pool'),
('landuse', 'retail',          'Normal', 250, 'Retail / Shopping Area'),
('amenity', 'parking',         'Normal', 200, 'Parking Facility'),
('landuse', 'commercial',      'Normal', 250, 'Commercial District'),
('landuse', 'residential',     'Normal', 250, 'Residential Area');

COMMIT;
