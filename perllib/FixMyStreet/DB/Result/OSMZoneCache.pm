use utf8;
package FixMyStreet::DB::Result::OSMZoneCache;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components(
  "FilterColumn",
  "+FixMyStreet::DB::JSONBColumn",
  "FixMyStreet::InflateColumn::DateTime",
  "FixMyStreet::EncodedColumn",
);

__PACKAGE__->table("osm_zone_cache");

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "osm_zone_cache_id_seq",
  },
  "latitude",
  { data_type => "numeric", size => [10, 7], is_nullable => 0 },
  "longitude",
  { data_type => "numeric", size => [10, 7], is_nullable => 0 },
  "radius_m",
  { data_type => "integer", default_value => 500, is_nullable => 0 },
  "osm_data",
  { data_type => "jsonb", is_nullable => 1 },
  "fetched_at",
  {
    data_type     => "timestamp",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable   => 0,
  },
  "expires_at",
  {
    data_type     => "timestamp",
    is_nullable   => 0,
  },
);

__PACKAGE__->set_primary_key("id");

1;
