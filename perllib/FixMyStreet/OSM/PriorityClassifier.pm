package FixMyStreet::OSM::PriorityClassifier;

=head1 NAME

FixMyStreet::OSM::PriorityClassifier - Auto-classify reports by nearby OSM zones

=head1 DESCRIPTION

Queries the OpenStreetMap Overpass API to find nearby points of interest
(hospitals, schools, parks, etc.) and assigns a priority level based on
the priority_zone_config table. The highest-priority match wins.

Priority mapping to existing response_priorities:
  Emergency → "Emergency"
  High      → "High"
  Normal    → "Normal"
  Low       → "Low" (default / no match)

=cut

use strict;
use warnings;

use LWP::UserAgent;
use JSON::MaybeXS;
use POSIX qw(floor);
use Math::Trig qw(deg2rad pi);
use FixMyStreet::DB;

# Priority levels in descending order of severity
my %PRIORITY_RANK = (
    'Emergency' => 4,
    'High'      => 3,
    'Normal'    => 2,
    'Low'       => 1,
);

my $OVERPASS_URL = 'https://overpass-api.de/api/interpreter';
my $CACHE_TTL_DAYS = 7;

=head2 classify($lat, $lon, $options)

Classify a location by nearby OSM zones.

Options:
  radius_m  - search radius (default: 500m, covers max configured zone radius)
  use_cache - whether to use DB cache (default: 1)

Returns hashref: {
    priority_level => 'Emergency'|'High'|'Normal'|'Low',
    zone_label     => 'Hospital',
    distance_m     => 142.5,
    matched_zones  => [ { label => ..., priority_level => ..., distance_m => ... }, ... ]
}

Returns undef on error or if no zones are configured.

=cut

sub classify {
    my ($class, $lat, $lon, $options) = @_;
    $options ||= {};
    my $radius_m  = $options->{radius_m} || 500;
    my $use_cache = exists $options->{use_cache} ? $options->{use_cache} : 1;

    # Load enabled zone configs
    my @configs = FixMyStreet::DB->resultset('PriorityZoneConfig')->search(
        { enabled => 1 },
        { order_by => 'priority_level' }
    )->all;

    return undef unless @configs;

    # Get OSM data (cached or fresh)
    my $elements = $class->_get_osm_elements($lat, $lon, $radius_m, \@configs, $use_cache);

    # API failure (undef) vs empty result (no elements found)
    return undef unless defined $elements;  # API error — caller should retry

    # No elements found → default to Low
    return { priority_level => 'Low', zone_label => undef, distance_m => undef, matched_zones => [] }
        unless @$elements;

    # Build lookup: "key=value" => config
    my %config_map;
    for my $cfg (@configs) {
        my $tag = $cfg->osm_key . '=' . $cfg->osm_value;
        $config_map{$tag} = $cfg;
    }

    # Score each element
    my @matches;
    for my $el (@$elements) {
        my $tags = $el->{tags} || {};
        my ($el_lat, $el_lon) = _element_center($el);
        next unless defined $el_lat && defined $el_lon;

        for my $key (keys %$tags) {
            my $tag = "$key=$tags->{$key}";
            my $cfg = $config_map{$tag};
            next unless $cfg;

            my $dist = _haversine($lat, $lon, $el_lat, $el_lon);
            next if $dist > $cfg->radius_m;

            push @matches, {
                priority_level => $cfg->priority_level,
                zone_label     => $cfg->label || "$key=$tags->{$key}",
                distance_m     => sprintf("%.1f", $dist),
                rank           => $PRIORITY_RANK{$cfg->priority_level} || 0,
            };
        }
    }

    return { priority_level => 'Low', zone_label => undef, distance_m => undef, matched_zones => [] }
        unless @matches;

    # Sort by rank (highest first), then by distance (closest first)
    @matches = sort { $b->{rank} <=> $a->{rank} || $a->{distance_m} <=> $b->{distance_m} } @matches;

    my $best = $matches[0];
    return {
        priority_level => $best->{priority_level},
        zone_label     => $best->{zone_label},
        distance_m     => $best->{distance_m},
        matched_zones  => \@matches,
    };
}

=head2 classify_and_save($report)

Classify a FixMyStreet problem report and save the results to the problem row.
Also sets response_priority_id to the matching priority for the report's body.

Returns the classification result hashref, or undef on error.

=cut

sub classify_and_save {
    my ($class, $report) = @_;
    return undef unless $report && $report->latitude && $report->longitude;

    # Don't override admin manual overrides
    return undef if $report->osm_zone_admin_override;

    my $result = eval { $class->classify($report->latitude, $report->longitude) };
    if ($@ || !$result) {
        warn "PriorityClassifier error for problem " . $report->id . ": " . ($@ || 'no result') . "\n";
        return undef;
    }

    # Update the problem's OSM zone columns
    $report->update({
        osm_zone_priority      => $result->{priority_level},
        osm_zone_label         => $result->{zone_label},
        osm_zone_classified_at => \'CURRENT_TIMESTAMP',
        osm_zone_distance_m    => $result->{distance_m},
    });

    # Map to response_priority_id
    $class->_set_response_priority($report, $result->{priority_level});

    # Auto-populate "Extra details" for Emergency and High priorities
    $class->_set_zone_explanation($report, $result);

    return $result;
}

=head2 reclassify_all($options)

Reclassify all unclassified (or all) reports.

Options:
  force     - reclassify even already-classified reports (default: 0)
  limit     - max reports to process (default: 100)
  body_id   - restrict to a specific body

Returns count of reports processed.

=cut

sub reclassify_all {
    my ($class, $options) = @_;
    $options ||= {};
    my $force = $options->{force} || 0;
    my $limit = $options->{limit} || 100;

    my %search;
    $search{osm_zone_classified_at} = undef unless $force;
    $search{osm_zone_admin_override} = 0 unless $force;

    if ($options->{body_id}) {
        $search{bodies_str} = { 'like', '%' . $options->{body_id} . '%' };
    }

    my @reports = FixMyStreet::DB->resultset('Problem')->search(
        \%search,
        { rows => $limit, order_by => { -desc => 'created' } }
    )->all;

    my $count = 0;
    for my $report (@reports) {
        my $result = eval { $class->classify_and_save($report) };
        if ($@ || !$result) {
            warn "Error classifying report " . $report->id . ": " . ($@ || 'no result') . "\n"
                unless !$result;  # don't double-warn; classify_and_save already warns
            next;
        }
        $count++;
        # Rate limit: sleep briefly between Overpass calls
        sleep(1) if $count % 10 == 0;
    }

    return $count;
}

# ---- Private methods ----

sub _get_osm_elements {
    my ($class, $lat, $lon, $radius_m, $configs, $use_cache) = @_;

    # Check cache first
    if ($use_cache) {
        my $cached = $class->_check_cache($lat, $lon, $radius_m);
        return $cached if $cached;
    }

    # Build Overpass query from enabled configs
    my $query = $class->_build_overpass_query($lat, $lon, $radius_m, $configs);
    return undef unless $query;

    my $ua = LWP::UserAgent->new(
        timeout => 30,
        agent   => 'InfraSignal/1.0 PriorityClassifier',
    );

    my $response = $ua->post($OVERPASS_URL, Content => "data=$query");
    unless ($response->is_success) {
        warn "Overpass API error: " . $response->status_line . "\n";
        return undef;
    }

    my $data = eval { decode_json($response->content) };
    if ($@ || !$data || !$data->{elements}) {
        warn "Overpass JSON parse error: $@\n";
        return undef;
    }

    my $elements = $data->{elements};

    # Store in cache
    if ($use_cache) {
        eval {
            FixMyStreet::DB->resultset('OSMZoneCache')->create({
                latitude   => sprintf("%.7f", $lat),
                longitude  => sprintf("%.7f", $lon),
                radius_m   => $radius_m,
                osm_data   => encode_json($elements),
                fetched_at => \'CURRENT_TIMESTAMP',
                expires_at => \"CURRENT_TIMESTAMP + INTERVAL '$CACHE_TTL_DAYS days'",
            });
        };
        warn "Cache store error: $@\n" if $@;
    }

    return $elements;
}

sub _check_cache {
    my ($class, $lat, $lon, $radius_m) = @_;

    # Look for a cached entry within ~100m of the requested location
    # Using simple lat/lon box approximation (0.001° ≈ 111m)
    my $delta = 0.001;

    my $cached = FixMyStreet::DB->resultset('OSMZoneCache')->search({
        latitude   => { '>=' => $lat - $delta, '<=' => $lat + $delta },
        longitude  => { '>=' => $lon - $delta, '<=' => $lon + $delta },
        radius_m   => { '>=' => $radius_m },
        expires_at => { '>'  => \'CURRENT_TIMESTAMP' },
    }, {
        order_by => { -desc => 'fetched_at' },
        rows     => 1,
    })->single;

    return undef unless $cached && $cached->osm_data;

    my $elements = eval { decode_json($cached->osm_data) };
    return $elements;
}

sub _build_overpass_query {
    my ($class, $lat, $lon, $radius_m, $configs) = @_;

    # Group configs by osm_key for efficient querying
    my %by_key;
    for my $cfg (@$configs) {
        push @{$by_key{$cfg->osm_key}}, $cfg->osm_value;
    }

    my @parts;
    for my $key (sort keys %by_key) {
        my $values = join('|', @{$by_key{$key}});
        # Query nodes, ways, and relations with these tags
        push @parts, qq{node["$key"~"^($values)\$"](around:$radius_m,$lat,$lon);};
        push @parts, qq{way["$key"~"^($values)\$"](around:$radius_m,$lat,$lon);};
    }

    return undef unless @parts;

    my $body = join("\n    ", @parts);
    return qq{[out:json][timeout:25];(\n    $body\n);out center;};
}

sub _element_center {
    my ($el) = @_;
    # Nodes have lat/lon directly
    if ($el->{type} eq 'node') {
        return ($el->{lat}, $el->{lon});
    }
    # Ways/relations: use 'center' from Overpass 'out center'
    if ($el->{center}) {
        return ($el->{center}{lat}, $el->{center}{lon});
    }
    return (undef, undef);
}

sub _haversine {
    my ($lat1, $lon1, $lat2, $lon2) = @_;
    my $R = 6371000; # Earth radius in metres

    my $dlat = deg2rad($lat2 - $lat1);
    my $dlon = deg2rad($lon2 - $lon1);
    my $a = sin($dlat/2)**2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dlon/2)**2;
    my $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

    return $R * $c;
}

sub _set_response_priority {
    my ($class, $report, $priority_level) = @_;

    # Get the body ID from the report
    my $bodies_str = $report->bodies_str;
    return unless $bodies_str;

    my ($body_id) = split /,/, $bodies_str;
    return unless $body_id;

    # Find the matching response_priority for this body
    my $rp = FixMyStreet::DB->resultset('ResponsePriority')->search({
        body_id => $body_id,
        name    => $priority_level,
        deleted => 0,
    })->single;

    if ($rp) {
        $report->update({ response_priority_id => $rp->id });
    }
}

# Hardcoded explanations for Emergency and High priorities.
# Auto-fills the "Extra details" (detailed_information) metadata field.
my %ZONE_EXPLANATIONS = (
    # Emergency zones
    'Hospital'              => 'EMERGENCY ZONE: Located near a hospital. Infrastructure damage in this area may impact emergency medical access, patient transport, and ambulance routes. Prioritize immediate response.',
    'Hospital Building'     => 'EMERGENCY ZONE: Located near a hospital facility. Infrastructure damage here may affect emergency services, patient safety, and critical medical operations.',
    'School'                => 'EMERGENCY ZONE: Located near a school. Children and staff safety is at risk. Infrastructure issues in school zones require urgent attention during school hours.',
    'School Building'       => 'EMERGENCY ZONE: Located near a school building. Student and staff safety is the top priority. Immediate action required.',
    'Kindergarten / Daycare'=> 'EMERGENCY ZONE: Located near a kindergarten or daycare. Young children are especially vulnerable. This area requires the fastest possible response.',
    'Fire Station'          => 'EMERGENCY ZONE: Located near a fire station. Infrastructure damage may delay emergency fire response and endanger the entire community.',

    # High priority zones
    'Police Station'        => 'HIGH PRIORITY: Located near a police station. Infrastructure issues may affect law enforcement response times and public safety operations.',
    'Medical Clinic'        => 'HIGH PRIORITY: Located near a medical clinic. Patients and healthcare workers depend on safe access to this facility.',
    'Nursing Home'          => 'HIGH PRIORITY: Located near a nursing home. Elderly and vulnerable residents require reliable infrastructure for mobility and emergency evacuation.',
    'Childcare Center'      => 'HIGH PRIORITY: Located near a childcare center. Young children are present — infrastructure safety is critical.',
    'University'            => 'HIGH PRIORITY: Located near a university campus. Large student population depends on safe infrastructure for daily commuting.',
    'College'               => 'HIGH PRIORITY: Located near a college. Students and staff require safe access routes and infrastructure.',
    'Community Center'      => 'HIGH PRIORITY: Located near a community center. This is a public gathering place used by families, seniors, and community groups.',
    'Library'               => 'HIGH PRIORITY: Located near a public library. Frequently visited by children, students, and seniors who rely on safe pedestrian access.',
    'Bus Station'           => 'HIGH PRIORITY: Located near a bus station. Public transit infrastructure damage affects commuters and may cause safety hazards for pedestrians.',
    'Train Station'         => 'HIGH PRIORITY: Located near a train station. Rail transit hubs serve large volumes of commuters — infrastructure issues create safety risks.',
    'Place of Worship'      => 'HIGH PRIORITY: Located near a place of worship. Regular gatherings of community members require safe access and infrastructure.',
    'Social Facility'       => 'HIGH PRIORITY: Located near a social services facility. Vulnerable populations depend on safe, accessible infrastructure in this area.',
    'Shelter'               => 'HIGH PRIORITY: Located near a shelter. Homeless and vulnerable individuals rely on safe infrastructure around this facility.',
    'Playground'            => 'HIGH PRIORITY: Located near a playground. Children are especially vulnerable to infrastructure hazards in recreational areas.',
    'Museum'                => 'HIGH PRIORITY: Located near a museum. Public cultural facility with regular foot traffic from families and tourists.',
    'Marketplace'           => 'HIGH PRIORITY: Located near a marketplace. High pedestrian traffic area where infrastructure damage poses safety risks to shoppers and vendors.',
    'Bus Stop'              => 'HIGH PRIORITY: Located near a bus stop. Transit riders, including elderly and disabled passengers, wait at this location and need safe infrastructure.',
);

sub _set_zone_explanation {
    my ($class, $report, $result) = @_;

    my $level = $result->{priority_level} || '';
    return unless $level eq 'Emergency' || $level eq 'High';

    my $label    = $result->{zone_label} || return;
    my $distance = $result->{distance_m} || '?';

    # Look up the hardcoded explanation
    my $explanation = $ZONE_EXPLANATIONS{$label};
    unless ($explanation) {
        # Fallback for any zone type not in the lookup
        $explanation = uc($level) . " PRIORITY: Located near $label ($distance m). This area requires elevated attention.";
    }

    # Append distance info
    $explanation .= " [Detected: ${distance}m from nearest $label]";

    $report->set_extra_metadata(detailed_information => $explanation);
    $report->update;
}

1;
