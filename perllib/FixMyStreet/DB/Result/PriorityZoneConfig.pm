use utf8;
package FixMyStreet::DB::Result::PriorityZoneConfig;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components(
  "FilterColumn",
  "+FixMyStreet::DB::JSONBColumn",
  "FixMyStreet::InflateColumn::DateTime",
  "FixMyStreet::EncodedColumn",
);

__PACKAGE__->table("priority_zone_config");

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "priority_zone_config_id_seq",
  },
  "osm_key",
  { data_type => "text", is_nullable => 0 },
  "osm_value",
  { data_type => "text", is_nullable => 0 },
  "priority_level",
  { data_type => "text", default_value => "Standard", is_nullable => 0 },
  "radius_m",
  { data_type => "integer", default_value => 250, is_nullable => 0 },
  "enabled",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "label",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable   => 0,
  },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("priority_zone_config_osm_key_osm_value_key", ["osm_key", "osm_value"]);

1;
