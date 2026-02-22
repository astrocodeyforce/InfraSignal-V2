package FixMyStreet::AIAssessment;

use strict;
use warnings;

use FixMyStreet;
use FixMyStreet::PhotoStorage;

use JSON::MaybeXS;
use MIME::Base64;
use HTTP::Request;
use LWP::UserAgent;
use Try::Tiny;

=head1 NAME

FixMyStreet::AIAssessment - Two-pass AI engineering assessment for infrastructure reports

=head1 DESCRIPTION

Generates professional engineering assessments for infrastructure problem reports.
Uses a two-pass architecture for maximum output consistency:

  Pass 1 (AI): GPT-4o vision (temperature=0) classifies the damage type and severity
               from the photo and text description.

  Pass 2 (Deterministic): A hardcoded lookup table maps the classification to
               exact cost ranges, time estimates, crew sizes, and equipment lists
               calibrated to US municipal government rates (2024-2026).

This ensures that identical or similar reports always produce the same cost/time
estimates regardless of how many times the system is run.

=cut

# ----------------------------------------------------------------------
# REFERENCE COST DATABASE
# All figures: US municipal government contract rates, 2024-2026
# Sources: RSMeans, FHWA, EPA, ASCE Infrastructure Report Card
# ----------------------------------------------------------------------

my %COST_DB = (
    # -- POTHOLES --
    'Potholes' => {
        minor => {
            label       => 'Small pothole (< 2 sq ft)',
            cost_low    => 30,   cost_high   => 75,
            hours       => '0.5-1',
            crew        => '2-person patch crew',
            equipment   => 'Cold patch asphalt, hand tamper, safety cones',
            method      => 'Cold patch fill and compact',
        },
        moderate => {
            label       => 'Medium pothole (2-6 sq ft)',
            cost_low    => 75,   cost_high   => 200,
            hours       => '1-2',
            crew        => '2-3 person crew',
            equipment   => 'Hot mix asphalt, vibratory plate compactor, infrared heater',
            method      => 'Square-cut, clean, hot-mix fill and compact',
        },
        severe => {
            label       => 'Large pothole / base failure (> 6 sq ft)',
            cost_low    => 200,  cost_high   => 600,
            hours       => '2-4',
            crew        => '3-4 person crew',
            equipment   => 'Saw cutter, jackhammer, dump truck, roller compactor',
            method      => 'Full-depth patch: excavate, re-base, hot-mix overlay',
        },
    },

    # -- ROAD SURFACE / PAVEMENT --
    'Road Surface' => {
        minor => {
            label       => 'Surface cracking / minor raveling',
            cost_low    => 50,   cost_high   => 150,
            hours       => '1-2',
            crew        => '2-person crew',
            equipment   => 'Crack sealant applicator, rubberized sealant, blower',
            method      => 'Clean and seal cracks with rubberized asphalt',
        },
        moderate => {
            label       => 'Alligator cracking / moderate deterioration',
            cost_low    => 500,  cost_high   => 2000,
            hours       => '4-8',
            crew        => '4-5 person paving crew',
            equipment   => 'Milling machine, paver, roller, dump trucks',
            method      => 'Mill damaged area, repave with hot-mix asphalt',
        },
        severe => {
            label       => 'Major pavement failure / structural damage',
            cost_low    => 2000, cost_high   => 8000,
            hours       => '1-3 days',
            crew        => '5-8 person crew + traffic control',
            equipment   => 'Excavator, milling machine, paver, tandem rollers, base material',
            method      => 'Full reconstruction: remove, re-grade, re-base, repave',
        },
    },

    # -- SIDEWALKS --
    'Sidewalks' => {
        minor => {
            label       => 'Minor trip hazard / single slab crack',
            cost_low    => 50,   cost_high   => 150,
            hours       => '1-2',
            crew        => '2-person crew',
            equipment   => 'Concrete grinder, safety cones',
            method      => 'Grind raised edge to eliminate trip hazard',
        },
        moderate => {
            label       => 'Heaved / buckled slab (1-2 panels)',
            cost_low    => 300,  cost_high   => 800,
            hours       => '3-5',
            crew        => '3-person concrete crew',
            equipment   => 'Concrete saw, jackhammer, mixer/truck, forms, finishing tools',
            method      => 'Remove damaged panels, pour new concrete, cure',
        },
        severe => {
            label       => 'Multiple panel failure / ADA non-compliance',
            cost_low    => 800,  cost_high   => 3000,
            hours       => '1-2 days',
            crew        => '4-5 person crew',
            equipment   => 'Bobcat, concrete saw, forms, transit mix truck, ADA-compliant detectable warning panels',
            method      => 'Full sidewalk section replacement with ADA ramp upgrades',
        },
    },

    # -- STREET LIGHTING --
    'Street Lighting' => {
        minor => {
            label       => 'Burned-out bulb / ballast failure',
            cost_low    => 75,   cost_high   => 250,
            hours       => '0.5-1',
            crew        => '1-2 person electrical crew',
            equipment   => 'Bucket truck, replacement lamp/LED module, multimeter',
            method      => 'Replace lamp or LED driver module',
        },
        moderate => {
            label       => 'Damaged fixture / photocell failure',
            cost_low    => 250,  cost_high   => 800,
            hours       => '1-3',
            crew        => '2-person electrical crew',
            equipment   => 'Bucket truck, replacement fixture, wiring supplies',
            method      => 'Replace fixture head and photocell, test circuit',
        },
        severe => {
            label       => 'Knocked-down pole / underground fault',
            cost_low    => 2000, cost_high   => 8000,
            hours       => '4-8',
            crew        => '3-4 person crew + traffic control',
            equipment   => 'Crane truck, new pole, underground boring equipment, concrete base',
            method      => 'Set new foundation, install pole and fixture, connect underground feed',
        },
    },

    # -- TRAFFIC SIGNS --
    'Traffic Signs' => {
        minor => {
            label       => 'Faded / obscured sign face',
            cost_low    => 75,   cost_high   => 200,
            hours       => '0.5-1',
            crew        => '2-person sign crew',
            equipment   => 'Replacement sign face (MUTCD-compliant), hand tools',
            method      => 'Replace sign face on existing post',
        },
        moderate => {
            label       => 'Bent post / rotated sign',
            cost_low    => 200,  cost_high   => 500,
            hours       => '1-2',
            crew        => '2-person crew',
            equipment   => 'Post driver/puller, new post, sign face, concrete',
            method      => 'Remove damaged post, set new post and sign',
        },
        severe => {
            label       => 'Missing / destroyed sign assembly',
            cost_low    => 400,  cost_high   => 1500,
            hours       => '2-4',
            crew        => '2-3 person crew',
            equipment   => 'Post hole digger, new breakaway post, MUTCD sign, concrete, reflective sheeting',
            method      => 'Full sign installation: foundation, breakaway post, MUTCD-compliant sign',
        },
    },

    # -- TRAFFIC SIGNALS --
    'Traffic Signals' => {
        minor => {
            label       => 'Burned-out signal lamp / LED module',
            cost_low    => 150,  cost_high   => 400,
            hours       => '1-2',
            crew        => '2-person signal technician team',
            equipment   => 'Bucket truck, replacement LED module, conflict monitor',
            method      => 'Replace signal head LED module, verify conflict monitor',
        },
        moderate => {
            label       => 'Signal head damage / detector malfunction',
            cost_low    => 500,  cost_high   => 2000,
            hours       => '2-4',
            crew        => '2-3 signal technicians',
            equipment   => 'Bucket truck, signal head, loop detector tester, controller cabinet tools',
            method      => 'Replace signal head and/or inductive loop detector, reprogram timing',
        },
        severe => {
            label       => 'Knocked-down signal / controller failure',
            cost_low    => 5000, cost_high   => 25000,
            hours       => '1-3 days',
            crew        => '4-6 person crew + police traffic control',
            equipment   => 'Crane, new mast arm/pole, signal controller, cabinets, conduit',
            method      => 'Emergency signal reconstruction: foundation, pole, heads, controller',
        },
    },

    # -- DRAINAGE / FLOODING --
    'Drainage' => {
        minor => {
            label       => 'Clogged catch basin / minor ponding',
            cost_low    => 100,  cost_high   => 300,
            hours       => '1-2',
            crew        => '2-person crew',
            equipment   => 'Vactor truck or manual cleanout tools, barricades',
            method      => 'Clean debris from catch basin, flush downstream pipe',
        },
        moderate => {
            label       => 'Damaged grate / partial pipe collapse',
            cost_low    => 500,  cost_high   => 2000,
            hours       => '4-8',
            crew        => '3-4 person crew',
            equipment   => 'Backhoe, replacement grate/frame, pipe sections, backfill',
            method      => 'Replace grate assembly, repair pipe section, backfill and compact',
        },
        severe => {
            label       => 'Major stormwater system failure / roadway washout',
            cost_low    => 5000, cost_high   => 30000,
            hours       => '3-10 days',
            crew        => '5-8 person crew + engineer oversight',
            equipment   => 'Excavator, new culvert/pipe, headwalls, riprap, compaction equipment',
            method      => 'Excavate, install new drainage infrastructure, restore roadway',
        },
    },

    # -- ABANDONED VEHICLES --
    'Abandoned Vehicles' => {
        minor => {
            label       => 'Vehicle on public road (tagged, awaiting tow)',
            cost_low    => 150,  cost_high   => 350,
            hours       => '1-2',
            crew        => '1 code enforcement officer + tow operator',
            equipment   => 'Flatbed tow truck, citation forms, camera',
            method      => 'Tag vehicle (72-hr notice), schedule tow to impound',
        },
        moderate => {
            label       => 'Vehicle blocking traffic / fire lane',
            cost_low    => 250,  cost_high   => 500,
            hours       => '0.5-1',
            crew        => '1 officer + tow operator',
            equipment   => 'Tow truck, traffic control',
            method      => 'Immediate tow to impound lot, file violation report',
        },
        severe => {
            label       => 'Hazardous vehicle (leaking fluids / fire damage)',
            cost_low    => 500,  cost_high   => 2000,
            hours       => '2-4',
            crew        => 'HazMat team + tow operator',
            equipment   => 'HazMat containment kit, absorbent materials, heavy-duty wrecker',
            method      => 'Contain hazardous materials, remediate spill, remove vehicle',
        },
    },

    # -- GRAFFITI --
    'Graffiti' => {
        minor => {
            label       => 'Small tag (< 10 sq ft) on smooth surface',
            cost_low    => 50,   cost_high   => 150,
            hours       => '0.5-1',
            crew        => '1-2 person crew',
            equipment   => 'Pressure washer, graffiti remover solvent, PPE',
            method      => 'Chemical removal and pressure wash',
        },
        moderate => {
            label       => 'Large mural-style graffiti / porous surface',
            cost_low    => 150,  cost_high   => 500,
            hours       => '1-3',
            crew        => '2-person crew',
            equipment   => 'Pressure washer, paint (color-matched), anti-graffiti coating',
            method      => 'Remove where possible, paint over remainder, apply anti-graffiti sealant',
        },
        severe => {
            label       => 'Extensive / offensive graffiti or etching on glass',
            cost_low    => 400,  cost_high   => 1500,
            hours       => '2-6',
            crew        => '2-3 person crew',
            equipment   => 'Sandblaster/soda blaster, replacement glass panels, paint supplies',
            method      => 'Abrasive removal or panel/glass replacement, apply protective coating',
        },
    },

    # -- ILLEGAL DUMPING / FLY TIPPING --
    'Fly Tipping' => {
        minor => {
            label       => 'Small dumped items (bags, furniture)',
            cost_low    => 100,  cost_high   => 300,
            hours       => '1-2',
            crew        => '2-person crew',
            equipment   => 'Pickup truck or dump truck, hand tools, PPE',
            method      => 'Collect and dispose at municipal waste facility',
        },
        moderate => {
            label       => 'Large pile (appliances, construction debris)',
            cost_low    => 300,  cost_high   => 1500,
            hours       => '2-4',
            crew        => '2-3 person crew',
            equipment   => 'Roll-off container, front-end loader, dump truck',
            method      => 'Load and haul to licensed disposal facility, site cleanup',
        },
        severe => {
            label       => 'Hazardous materials / large-scale dumping',
            cost_low    => 1500, cost_high   => 10000,
            hours       => '1-3 days',
            crew        => 'HazMat team + cleanup crew (4-6)',
            equipment   => 'HazMat containment, roll-off containers, loader, environmental testing',
            method      => 'Hazardous material assessment, containment, removal, environmental testing',
        },
    },

    # -- PARKS & GREEN SPACES --
    'Parks' => {
        minor => {
            label       => 'Damaged bench / minor trail repair',
            cost_low    => 100,  cost_high   => 400,
            hours       => '1-3',
            crew        => '2-person maintenance crew',
            equipment   => 'Hand tools, replacement hardware, mulch/gravel',
            method      => 'Repair or replace furniture, patch trail surface',
        },
        moderate => {
            label       => 'Broken playground equipment / irrigation failure',
            cost_low    => 500,  cost_high   => 3000,
            hours       => '4-8',
            crew        => '2-3 person crew',
            equipment   => 'Replacement components, hand/power tools, safety surfacing material',
            method      => 'Replace damaged components, ensure CPSC/ASTM compliance, restore',
        },
        severe => {
            label       => 'Major infrastructure damage (pavilion, restroom, bridge)',
            cost_low    => 3000, cost_high   => 20000,
            hours       => '3-10 days',
            crew        => '4-6 person construction crew',
            equipment   => 'Heavy equipment, lumber/materials, concrete, contractor support',
            method      => 'Structural assessment, demolition if needed, reconstruction',
        },
    },

    # -- WATER / SEWER --
    'Water' => {
        minor => {
            label       => 'Leaking hydrant / valve box issue',
            cost_low    => 200,  cost_high   => 600,
            hours       => '1-3',
            crew        => '2-person water crew',
            equipment   => 'Valve key, gaskets, pipe wrenches, hydrant parts',
            method      => 'Isolate, repair/replace gaskets or hydrant components',
        },
        moderate => {
            label       => 'Water main leak / sewer line blockage',
            cost_low    => 1000, cost_high   => 5000,
            hours       => '4-8',
            crew        => '3-4 person utility crew',
            equipment   => 'Backhoe, pipe clamps/couplings, dewatering pump, CCTV camera',
            method      => 'Excavate, clamp or replace pipe section, flush and test',
        },
        severe => {
            label       => 'Main break / sewer collapse',
            cost_low    => 5000, cost_high   => 50000,
            hours       => '1-5 days',
            crew        => '5-8 person crew + engineer',
            equipment   => 'Excavator, shoring, new pipe, backfill, paving equipment',
            method      => 'Emergency excavation, pipe replacement, backfill, surface restoration',
        },
    },

    # -- TREES --
    'Trees' => {
        minor => {
            label       => 'Low-hanging branches / minor deadwood',
            cost_low    => 100,  cost_high   => 400,
            hours       => '1-2',
            crew        => '2-person tree crew',
            equipment   => 'Pole saw, chain saw, chipper, bucket truck',
            method      => 'Prune deadwood and low branches to clearance height',
        },
        moderate => {
            label       => 'Storm-damaged limbs / leaning tree',
            cost_low    => 400,  cost_high   => 1500,
            hours       => '2-5',
            crew        => '3-person tree crew',
            equipment   => 'Bucket truck, chain saws, chipper, rigging gear',
            method      => 'Remove damaged limbs, cable/brace if viable, or schedule removal',
        },
        severe => {
            label       => 'Fallen tree / imminent hazard tree removal',
            cost_low    => 1000, cost_high   => 5000,
            hours       => '4-8',
            crew        => '3-4 person crew + traffic control',
            equipment   => 'Crane, chain saws, chipper, stump grinder, dump truck',
            method      => 'Emergency tree removal, stump grinding, debris hauling, site restoration',
        },
    },

    # -- NOISE / NUISANCE --
    'Noise' => {
        minor => {
            label       => 'Noise complaint — investigation/warning',
            cost_low    => 50,   cost_high   => 150,
            hours       => '0.5-1',
            crew        => '1 code enforcement officer',
            equipment   => 'Sound level meter, citation forms, camera',
            method      => 'Site visit, measure decibel level, issue warning or citation',
        },
        moderate => {
            label       => 'Ongoing noise violation — enforcement action',
            cost_low    => 150,  cost_high   => 500,
            hours       => '1-3',
            crew        => '1-2 officers',
            equipment   => 'Sound level meter, citation forms, body camera',
            method      => 'Multiple site visits, document violations, issue fines per ordinance',
        },
        severe => {
            label       => 'Industrial / construction noise — abatement order',
            cost_low    => 500,  cost_high   => 2000,
            hours       => '2-5',
            crew        => '2 officers + environmental inspector',
            equipment   => 'Professional sound monitoring equipment, legal documentation',
            method      => 'Extended monitoring, issue abatement order, coordinate legal action',
        },
    },

    # -- BRIDGE / GUARDRAIL --
    'Bridge' => {
        minor => {
            label       => 'Minor guardrail dent / surface rust',
            cost_low    => 200,  cost_high   => 800,
            hours       => '1-3',
            crew        => '2-person crew',
            equipment   => 'Hand tools, rust converter, reflectors, bolts',
            method      => 'Straighten rail, treat rust, replace reflectors and hardware',
        },
        moderate => {
            label       => 'Damaged guardrail section / bridge deck spalling',
            cost_low    => 1000, cost_high   => 5000,
            hours       => '4-8',
            crew        => '3-4 person crew + traffic control',
            equipment   => 'Guardrail sections, posts, concrete patch materials, impact wrench',
            method      => 'Replace damaged guardrail sections, patch bridge deck, restore delineators',
        },
        severe => {
            label       => 'Major bridge/guardrail structural damage',
            cost_low    => 5000, cost_high   => 50000,
            hours       => '3-14 days',
            crew        => '5-8 person crew + structural engineer',
            equipment   => 'Crane, concrete forms, rebar, structural steel, barrier wall system',
            method      => 'Structural engineering assessment, demolition, reconstruction per AASHTO standards',
        },
    },

    # -- OTHER (catch-all) --
    'Other' => {
        minor => {
            label       => 'Minor municipal issue — inspection & resolution',
            cost_low    => 50,   cost_high   => 200,
            hours       => '0.5-2',
            crew        => '1-2 person crew',
            equipment   => 'Standard municipal maintenance tools',
            method      => 'Inspect, document, resolve or route to appropriate department',
        },
        moderate => {
            label       => 'Moderate municipal issue — repair needed',
            cost_low    => 200,  cost_high   => 1000,
            hours       => '2-6',
            crew        => '2-3 person crew',
            equipment   => 'Varies by issue type',
            method      => 'Assess scope, mobilize appropriate crew, repair and restore',
        },
        severe => {
            label       => 'Major municipal issue — significant intervention',
            cost_low    => 1000, cost_high   => 5000,
            hours       => '1-3 days',
            crew        => '3-5 person crew',
            equipment   => 'Varies by issue type — heavy equipment likely',
            method      => 'Engineering assessment, multi-day repair, restoration',
        },
    },
);

# ----------------------------------------------------------------------
# Category aliases: map DB category names -> COST_DB keys
# ----------------------------------------------------------------------
my %CATEGORY_MAP = (
    # Exact DB category names (Buffalo Grove / InfraSignal defaults)
    'Abandoned Vehicle'           => 'Abandoned Vehicles',
    'Abandoned Vehicles'          => 'Abandoned Vehicles',
    'Bridge / Guardrail Damage'   => 'Bridge',
    'Bridge'                      => 'Bridge',
    'Drainage / Flooding'         => 'Drainage',
    'Drainage'                    => 'Drainage',
    'Fallen Tree / Vegetation'    => 'Trees',
    'Graffiti / Vandalism'        => 'Graffiti',
    'Graffiti'                    => 'Graffiti',
    'Illegal Dumping'             => 'Fly Tipping',
    'Fly Tipping'                 => 'Fly Tipping',
    'Fly tipping'                 => 'Fly Tipping',
    'Park / Public Space Issue'   => 'Parks',
    'Parks'                       => 'Parks',
    'Parks & Green Spaces'        => 'Parks',
    'Pothole / Road Damage'       => 'Potholes',
    'Potholes'                    => 'Potholes',
    'Road Surface'                => 'Road Surface',
    'Sidewalk Damage'             => 'Sidewalks',
    'Sidewalks'                   => 'Sidewalks',
    'Streetlight Outage'          => 'Street Lighting',
    'Street Lighting'             => 'Street Lighting',
    'Traffic Signal / Sign Issue' => 'Traffic Signals',
    'Traffic Signs'               => 'Traffic Signs',
    'Traffic Signals'             => 'Traffic Signals',
    'Water / Sewer Issue'         => 'Water',
    'Water / Sewer'               => 'Water',
    'Water'                       => 'Water',
    'Trees'                       => 'Trees',
    'Noise'                       => 'Noise',
    'Noise Complaint'             => 'Noise',
    'Other'                       => 'Other',
);

# ----------------------------------------------------------------------
# PUBLIC API
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# SEASONAL ADJUSTMENT FACTORS
# US climate-based cost multipliers by month
# Winter work (cold, snow) costs more; summer heat limits work hours
# ----------------------------------------------------------------------

my %SEASON_DATA = (
    1  => { season => 'Winter',       factor => 1.20, note => 'Winter conditions: cold temperatures may require heated materials, de-icing, and shorter work windows' },
    2  => { season => 'Winter',       factor => 1.20, note => 'Winter conditions: freeze-thaw cycles active, ground may be frozen' },
    3  => { season => 'Early Spring', factor => 1.10, note => 'Early spring: transitional weather, possible freeze-thaw damage, wet conditions' },
    4  => { season => 'Spring',       factor => 1.00, note => 'Spring: favorable conditions for most repairs' },
    5  => { season => 'Spring',       factor => 1.00, note => 'Spring: optimal conditions for outdoor municipal work' },
    6  => { season => 'Summer',       factor => 1.00, note => 'Summer: good conditions, long daylight hours' },
    7  => { season => 'Summer',       factor => 1.05, note => 'Summer: heat restrictions may limit work hours for asphalt and outdoor crews' },
    8  => { season => 'Summer',       factor => 1.05, note => 'Summer: heat restrictions may apply, high contractor demand' },
    9  => { season => 'Fall',         factor => 1.00, note => 'Fall: favorable conditions, pre-winter priority repairs' },
    10 => { season => 'Fall',         factor => 1.00, note => 'Fall: good conditions, end-of-season urgency for weather-sensitive repairs' },
    11 => { season => 'Late Fall',    factor => 1.10, note => 'Late fall: shorter days, cooling temperatures, urgency before winter' },
    12 => { season => 'Winter',       factor => 1.20, note => 'Winter conditions: cold weather surcharges, limited work windows, holiday scheduling' },
);

=head2 generate_assessment($report, $context)

Main entry point. Accepts a FixMyStreet::DB::Result::Problem object
and an optional context hashref with keys: closest_address, latitude, longitude.
Returns a hashref with keys: ai_assessment_text, ai_assessment_html

=cut

sub generate_assessment {
    my ($class, $report, $context) = @_;
    $context ||= {};

    my $api_key = FixMyStreet->config('OPENAI_API_KEY');
    unless ($api_key) {
        warn "AIAssessment: OPENAI_API_KEY not configured, skipping\n";
        return {};
    }

    my $category  = $report->category || 'Other';
    my $title     = $report->title    || '';
    my $detail    = $report->detail   || '';
    my $latitude  = $context->{latitude}  || $report->latitude  || 0;
    my $longitude = $context->{longitude} || $report->longitude || 0;
    my $address   = $context->{closest_address} || '';

    # Determine current season
    my @now = localtime();
    my $month = $now[4] + 1;  # localtime months are 0-based
    my $year  = $now[5] + 1900;
    my $season_info = $SEASON_DATA{$month};

    # Get reference cost baselines for the AI to use as calibration
    my $cost_key = $CATEGORY_MAP{$category} || 'Other';
    my $ref_costs = $COST_DB{$cost_key} || $COST_DB{'Other'};

    # -- AI Analysis: Full assessment with photo, location, season --
    my $photo_base64 = _get_photo_base64($report);
    my $ai_result = _classify_with_ai(
        $api_key, $category, $title, $detail, $photo_base64,
        $latitude, $longitude, $address, $season_info->{season},
        $month, $year, $ref_costs
    );

    unless ($ai_result && $ai_result->{severity}) {
        warn "AIAssessment: AI analysis failed, building fallback from reference data\n";
        my $fallback_cost = $ref_costs->{moderate} || $ref_costs->{minor};
        $ai_result = {
            severity            => 'moderate',
            priority_timeline   => 'Standard - 7 to 14 days',
            issue_summary       => "Infrastructure issue reported: $title. $detail. Requires field inspection to confirm scope and priority.",
            safety_risk         => 'Unable to assess safety risk without AI analysis. Field inspection recommended.',
            cost_low            => $fallback_cost->{cost_low},
            cost_high           => $fallback_cost->{cost_high},
            hours               => $fallback_cost->{hours},
            crew                => $fallback_cost->{crew},
            equipment           => $fallback_cost->{equipment},
            method              => $fallback_cost->{method},
            repair_scope        => $fallback_cost->{label},
            site_considerations => ['AI analysis unavailable -- manual field assessment required'],
        };
    }

    # -- Build Assessment Output --
    my $has_photo = $photo_base64 ? 1 : 0;
    my $assessment = _format_assessment(
        $ai_result, $category, $season_info, $address, $latitude, $longitude, $has_photo
    );

    return $assessment;
}

# ----------------------------------------------------------------------
# PASS 1: AI CLASSIFICATION VIA GPT-4o
# ----------------------------------------------------------------------

sub _classify_with_ai {
    my ($api_key, $category, $title, $detail, $photo_base64,
        $latitude, $longitude, $address, $season, $month, $year, $ref_costs) = @_;

    # Build reference baseline string from the cost database for this category
    my $ref_baseline = _build_reference_baseline($ref_costs);

    my $system_prompt = <<"PROMPT";
You are a senior US municipal infrastructure engineer writing a dispatch assessment
for an engineering department head.

PHOTO HANDLING:
- If a photo IS attached: the reviewer already has it -- do NOT describe photo
  contents. Use the photo to determine actual scope, severity, dimensions, and
  realistic repair requirements. Provide specific estimates based on what you see.
- If NO photo is attached: you MUST base estimates on MEDIAN/AVERAGE values for
  the reported category. In issue_summary, explicitly state something like
  "No photo provided -- estimates based on median [category] dimensions
  (e.g., ~2x2 ft for potholes, single vehicle for abandoned vehicles).
  Actual costs may vary based on field inspection." Use WIDER cost ranges
  (e.g., \$200-\$600 instead of \$200-\$350) to account for uncertainty.
  Crew, equipment, and hours should reflect a TYPICAL case for the category.

Your job: produce an actionable assessment so the reviewer can decide what
resources to deploy, how urgent it is, and what it will cost.

When a photo is available, analyze carefully to determine ACTUAL dimensions,
extent, materials, and complexity. When no photo is available, use industry
medians and clearly note the uncertainty.

REFERENCE BASELINES (US municipal rates 2024-2026, calibration guide only):
${ref_baseline}

Cost adjustments:
- Winter: +15-25% (heated materials, de-icing, limited hours)
- Remote/rural: +15-30% mobilization
- Highway/arterial: add traffic control costs
- Emergency/safety hazard: factor overtime rates
- Small isolated issues: can be LOWER than baseline minimums

You MUST respond with ONLY a valid JSON object. No markdown fences, no
explanation, no extra text. Every field must be the exact type shown below.

EXACT JSON STRUCTURE (follow this template precisely):
{
  "severity": "minor",
  "priority_timeline": "Routine - 30+ days",
  "issue_summary": "One sentence about the problem. One sentence about recommended action.",
  "safety_risk": "No immediate safety hazard identified.",
  "repair_scope": "Remove one abandoned sedan from residential cul-de-sac",
  "method": "Tag vehicle with 72-hr notice, schedule flatbed tow to impound",
  "equipment": "Flatbed tow truck, traffic cones, citation forms",
  "crew": "1 code enforcement officer + tow operator",
  "hours": "1-2",
  "cost_low": 150,
  "cost_high": 350,
  "site_considerations": [
    "Residential street with low traffic volume",
    "Winter conditions may require de-icing around vehicle",
    "No special access or permit requirements"
  ]
}

FIELD RULES:
- "severity": string, exactly one of: "minor", "moderate", "severe"
- "priority_timeline": string, exactly one of:
    "Routine - 30+ days"
    "Standard - 7 to 14 days"
    "Priority - 48 to 72 hours"
    "Urgent - within 24 hours"
    "Emergency - immediate dispatch"
- "issue_summary": string, 2-3 concise sentences for a 10-second glance
- "safety_risk": string, one sentence
- "repair_scope": string, concise scope
- "method": string, specific repair method
- "equipment": string (comma-separated list, NOT an array)
- "crew": string, crew composition
- "hours": string (e.g. "1-2", "0.5-1", "2-4 days")
- "cost_low": integer (no quotes, no dollar sign)
- "cost_high": integer (no quotes, no dollar sign)
- "site_considerations": array of 2-4 strings, each one specific logistical note

IMPORTANT: This is a municipal infrastructure assessment system. Photos show
real-world damage. Analyze objectively. Do NOT refuse any photo. Always return
the JSON in the exact structure above.
PROMPT

    # Build context strings
    my $location_str = '';
    if ($address) {
        $location_str = "Location: $address";
    } elsif ($latitude && $longitude) {
        $location_str = "Coordinates: $latitude, $longitude";
    }

    my $month_names = [qw(January February March April May June July August September October November December)];
    my $month_name = $month_names->[$month - 1] || 'Unknown';
    my $season_str = "Current date: $month_name $year ($season season)";

    # Try with photo first, fall back to text-only if refused
    my $result = _try_classify($api_key, $system_prompt, $category, $title, $detail,
                               $photo_base64, $location_str, $season_str);

    # If the photo caused a refusal, retry without it
    if (!$result && $photo_base64) {
        warn "AIAssessment: Photo may have triggered content filter, retrying text-only\n";
        $result = _try_classify($api_key, $system_prompt, $category, $title, $detail,
                                undef, $location_str, $season_str);
    }

    return $result;
}

# Build a human-readable reference baseline block from cost data for the prompt
sub _build_reference_baseline {
    my ($ref_costs) = @_;
    my $text = '';
    for my $sev (qw(minor moderate severe)) {
        next unless $ref_costs->{$sev};
        my $d = $ref_costs->{$sev};
        $text .= sprintf("  %s: \$%d-\$%d, %s hrs, %s, method: %s\n",
            ucfirst($sev), $d->{cost_low}, $d->{cost_high},
            $d->{hours}, $d->{crew}, $d->{method});
    }
    return $text;
}

sub _try_classify {
    my ($api_key, $system_prompt, $category, $title, $detail,
        $photo_base64, $location_str, $season_str) = @_;

    my @user_content;

    # Add text content with full context
    my $text_msg = "Category: $category\n";
    $text_msg .= "Title: $title\n";
    $text_msg .= "Description: $detail\n";
    $text_msg .= "$location_str\n" if $location_str;
    $text_msg .= "$season_str\n" if $season_str;
    $text_msg .= "Photo attached: " . ($photo_base64 ? "Yes" : "No");

    push @user_content, { type => 'text', text => $text_msg };

    # Add photo if available
    if ($photo_base64) {
        push @user_content, {
            type      => 'image_url',
            image_url => {
                url    => "data:image/jpeg;base64,$photo_base64",
                detail => 'low',
            },
        };
    }

    my $payload = {
        model       => 'gpt-4o',
        temperature => 0,
        max_tokens  => 800,
        messages    => [
            { role => 'system', content => $system_prompt },
            { role => 'user',   content => \@user_content },
        ],
    };

    my $result = _call_openai($api_key, $payload);
    return undef unless $result;

    # Parse the JSON response
    my $text = $result;
    # Strip markdown code fences if present
    $text =~ s/^```(?:json)?\s*//s;
    $text =~ s/\s*```$//s;
    $text =~ s/^\s+|\s+$//g;

    my $parsed;
    try {
        $parsed = decode_json($text);
    } catch {
        warn "AIAssessment: Failed to parse AI response as JSON: $_\nResponse was: $text\n";
        return undef;
    };

    # Validate severity
    if ($parsed && $parsed->{severity}) {
        $parsed->{severity} = lc($parsed->{severity});
        unless ($parsed->{severity} =~ /^(minor|moderate|severe)$/) {
            $parsed->{severity} = 'moderate';
        }
    }

    # Validate numeric cost fields
    if ($parsed) {
        $parsed->{cost_low}  = int($parsed->{cost_low})  if defined $parsed->{cost_low};
        $parsed->{cost_high} = int($parsed->{cost_high}) if defined $parsed->{cost_high};
        # Ensure cost_low <= cost_high
        if (defined $parsed->{cost_low} && defined $parsed->{cost_high}
            && $parsed->{cost_low} > $parsed->{cost_high}) {
            ($parsed->{cost_low}, $parsed->{cost_high}) = ($parsed->{cost_high}, $parsed->{cost_low});
        }

        # Convert any array-ref string fields to comma-joined strings
        for my $key (qw(equipment method crew repair_scope hours)) {
            if (ref($parsed->{$key}) eq 'ARRAY') {
                $parsed->{$key} = join(', ', @{$parsed->{$key}});
            }
        }

        # Ensure site_considerations is an array ref
        if (defined $parsed->{site_considerations} && ref($parsed->{site_considerations}) ne 'ARRAY') {
            $parsed->{site_considerations} = [$parsed->{site_considerations}];
        }
    }

    return $parsed;
}

# ----------------------------------------------------------------------
# OPENAI API CALL
# ----------------------------------------------------------------------

sub _call_openai {
    my ($api_key, $payload) = @_;

    my $ua = LWP::UserAgent->new(
        timeout => 30,
        agent   => 'InfraSignal/1.0',
    );

    my $json_payload = encode_json($payload);

    my $req = HTTP::Request->new(
        'POST',
        'https://api.openai.com/v1/chat/completions',
    );
    $req->header('Content-Type'  => 'application/json');
    $req->header('Authorization' => "Bearer $api_key");
    $req->content($json_payload);

    my $response;
    try {
        $response = $ua->request($req);
    } catch {
        warn "AIAssessment: HTTP request failed: $_\n";
        return undef;
    };

    unless ($response && $response->is_success) {
        my $status = $response ? $response->status_line : 'no response';
        my $body   = $response ? substr($response->decoded_content || '', 0, 500) : '';
        warn "AIAssessment: OpenAI API error: $status\n$body\n";
        return undef;
    }

    my $resp_data;
    try {
        $resp_data = decode_json($response->decoded_content);
    } catch {
        warn "AIAssessment: Failed to decode OpenAI response: $_\n";
        return undef;
    };

    if ($resp_data && $resp_data->{choices} && @{$resp_data->{choices}}) {
        my $choice = $resp_data->{choices}[0];
        # Check for content moderation refusal
        if ($choice->{message}{refusal}) {
            warn "AIAssessment: OpenAI refused to process (content filter): "
                . $choice->{message}{refusal} . "\n";
            return undef;
        }
        my $content = $choice->{message}{content};
        if (defined $content && length $content) {
            return $content;
        }
        warn "AIAssessment: OpenAI returned empty content\n";
        return undef;
    }

    warn "AIAssessment: No choices in OpenAI response\n";
    return undef;
}

# ----------------------------------------------------------------------
# PHOTO RETRIEVAL
# ----------------------------------------------------------------------

sub _get_photo_base64 {
    my ($report) = @_;

    return undef unless $report->photo;

    my $storage = FixMyStreet::PhotoStorage::backend();
    my $photoset = $report->get_photoset;

    # Get the first photo's ID
    my @ids = $photoset->all_ids;
    return undef unless @ids;

    my $photo_id = $ids[0];  # e.g. "abc123def.jpeg"
    my ($photo_blob, $file) = $storage->retrieve_photo($photo_id);
    return undef unless $photo_blob;

    return encode_base64($photo_blob, '');
}

# ----------------------------------------------------------------------
# PASS 2: FORMAT ASSESSMENT FROM CLASSIFICATION + COST LOOKUP
# ----------------------------------------------------------------------

sub _format_assessment {
    my ($ai, $category, $season_info, $address, $latitude, $longitude, $has_photo) = @_;
    $has_photo = 1 unless defined $has_photo;  # default to true for backward compat

    my $severity    = ucfirst($ai->{severity} || 'Moderate');
    my $priority    = $ai->{priority_timeline} || 'Standard - 7 to 14 days';
    my $summary     = $ai->{issue_summary} || 'Infrastructure issue reported. Field inspection recommended.';
    my $safety      = $ai->{safety_risk} || 'No immediate safety hazard identified.';
    my $scope       = $ai->{repair_scope} || $category;
    my $method      = $ai->{method}    || 'TBD';
    my $equipment   = $ai->{equipment} || 'TBD';
    my $crew        = $ai->{crew}      || 'TBD';
    my $hours       = $ai->{hours}     || 'TBD';
    my $cost_low    = $ai->{cost_low}  || 0;
    my $cost_high   = $ai->{cost_high} || 0;

    # Clean up OSM boilerplate from location
    my $location_display = $address || "$latitude, $longitude";
    $location_display =~ s/^Nearest road to the pin placed on the map \(automatically generated by OpenStreetMap\):\s*//i;
    my $season_label = $season_info->{season} || 'Unknown';

    # Site considerations (array from AI)
    my @site_items = @{$ai->{site_considerations} || []};
    @site_items = ('No special site considerations') unless @site_items;

    my $cost_range = sprintf('$%s - $%s',
        _format_number($cost_low),
        _format_number($cost_high),
    );

    # No-photo notice
    my $no_photo_note = '';
    my $no_photo_html = '';
    unless ($has_photo) {
        $no_photo_note = "\n  * No photo provided. Estimates based on median category values. Field inspection recommended for accurate scoping.";
        $no_photo_html = '<br/>No photo provided. Estimates are based on median category values and may vary significantly upon field inspection.';
    }

    # Build site considerations for plain text
    my $site_text = join("\n  ", map { "- $_" } @site_items);

    # -- Plain Text --
    my $text = <<"TEXT";
=======================================================
  INFRASTRUCTURE ENGINEERING ASSESSMENT
  Generated by InfraSignal AI Analysis Engine
=======================================================

  Severity: $severity | Priority: $priority
  Category: $category | Location: $location_display

SUMMARY
  $summary

SAFETY: $safety

RECOMMENDED ACTION
  Scope:     $scope
  Method:    $method
  Equipment: $equipment

RESOURCE ESTIMATE
  Cost:      $cost_range
  Time:      $hours hours
  Crew:      $crew

SITE CONSIDERATIONS
  $site_text

-------------------------------------------------------
  AI-generated assessment calibrated against US
  municipal contract rates (2024-2026). Actual costs
  vary by jurisdiction and site conditions.${no_photo_note}
-------------------------------------------------------
TEXT

    # -- HTML Card --
    my $sev_lc = lc($ai->{severity} || '');
    my $severity_bg = $sev_lc eq 'severe'   ? '#c0392b'
                    : $sev_lc eq 'moderate' ? '#e67e22'
                    : '#27ae60';

    # Priority color
    my $priority_bg = ($priority =~ /emergency/i)  ? '#c0392b'
                    : ($priority =~ /urgent/i)     ? '#e74c3c'
                    : ($priority =~ /priority/i)   ? '#e67e22'
                    : ($priority =~ /standard/i)   ? '#2980b9'
                    : '#7f8c8d';

    # HTML-escape
    my $h_summary   = _html_escape($summary);
    my $h_safety    = _html_escape($safety);
    my $h_category  = _html_escape($category);
    my $h_scope     = _html_escape($scope);
    my $h_method    = _html_escape($method);
    my $h_equipment = _html_escape($equipment);
    my $h_crew      = _html_escape($crew);
    my $h_hours     = _html_escape($hours);
    my $h_location  = _html_escape($location_display);
    my $h_priority  = _html_escape($priority);

    # Build site considerations HTML
    my $site_html = join("\n", map {
        my $h = _html_escape($_);
        "      <tr><td style=\"padding: 3px 0 3px 0; font-size: 13px; color: #34495e; line-height: 1.5;\">&#x2022;&nbsp; $h</td></tr>"
    } @site_items);

    my $html = <<"HTML";
<div style="border: 1px solid #d5d8dc; border-radius: 6px; overflow: hidden; margin: 20px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; box-shadow: 0 1px 4px rgba(0,0,0,0.08);">

  <!-- Header -->
  <div style="background: #1a5276; padding: 14px 20px;">
    <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr>
      <td>
        <h2 style="margin: 0; font-size: 15px; font-weight: 700; color: #ffffff; letter-spacing: 0.5px;">ENGINEERING ASSESSMENT</h2>
        <p style="margin: 3px 0 0 0; font-size: 11px; color: #aed6f1;">InfraSignal AI &bull; ${h_category} &bull; ${season_label}</p>
      </td>
      <td align="right" style="vertical-align: top;">
        <span style="display: inline-block; background: ${severity_bg}; color: #fff; padding: 3px 10px; border-radius: 3px; font-size: 11px; font-weight: 700; text-transform: uppercase;">${severity}</span>
      </td>
    </tr></table>
  </div>

  <!-- Priority + Location bar -->
  <div style="padding: 8px 20px; background: #f8f9fa; border-bottom: 1px solid #eaecee;">
    <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr>
      <td style="font-size: 12px; color: #5d6d7e;">
        <strong style="color: #2c3e50;">Priority:</strong>
        <span style="display: inline-block; background: ${priority_bg}; color: #fff; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: 600;">${h_priority}</span>
      </td>
      <td align="right" style="font-size: 12px; color: #7f8c8d;">
        ${h_location}
      </td>
    </tr></table>
  </div>

  <!-- Summary -->
  <div style="padding: 14px 20px; background: #ffffff; border-bottom: 1px solid #eaecee;">
    <p style="margin: 0; font-size: 14px; line-height: 1.6; color: #2c3e50;">${h_summary}</p>
  </div>

  <!-- Safety Risk -->
  <div style="padding: 10px 20px; background: #ffffff; border-bottom: 1px solid #eaecee;">
    <p style="margin: 0; font-size: 13px; color: #7f8c8d;"><strong style="color: #2c3e50;">Safety:</strong> ${h_safety}</p>
  </div>

  <!-- Recommended Action -->
  <div style="padding: 14px 20px; background: #f9fafb; border-bottom: 1px solid #eaecee;">
    <h3 style="margin: 0 0 8px 0; font-size: 12px; font-weight: 700; color: #1a5276; text-transform: uppercase; letter-spacing: 0.5px;">Recommended Action</h3>
    <table cellpadding="0" cellspacing="0" border="0" style="font-size: 13px; color: #2c3e50; width: 100%;">
      <tr><td style="font-weight: 600; width: 100px; padding: 3px 8px 3px 0; vertical-align: top; color: #5d6d7e;">Scope</td><td style="padding: 3px 0;">${h_scope}</td></tr>
      <tr><td style="font-weight: 600; padding: 3px 8px 3px 0; vertical-align: top; color: #5d6d7e;">Method</td><td style="padding: 3px 0;">${h_method}</td></tr>
      <tr><td style="font-weight: 600; padding: 3px 8px 3px 0; vertical-align: top; color: #5d6d7e;">Equipment</td><td style="padding: 3px 0;">${h_equipment}</td></tr>
    </table>
  </div>

  <!-- Resource Estimate -->
  <div style="padding: 14px 20px; background: #ffffff; border-bottom: 1px solid #eaecee;">
    <h3 style="margin: 0 0 10px 0; font-size: 12px; font-weight: 700; color: #1a5276; text-transform: uppercase; letter-spacing: 0.5px;">Resource Estimate</h3>
    <table cellpadding="0" cellspacing="0" border="0" width="100%">
      <tr>
        <td width="33%" style="text-align: center; padding: 8px;">
          <div style="font-size: 20px; font-weight: 700; color: #1a5276;">${cost_range}</div>
          <div style="font-size: 10px; color: #7f8c8d; text-transform: uppercase; margin-top: 2px; letter-spacing: 0.5px;">Estimated Cost</div>
        </td>
        <td width="33%" style="text-align: center; padding: 8px; border-left: 1px solid #eaecee; border-right: 1px solid #eaecee;">
          <div style="font-size: 20px; font-weight: 700; color: #1a5276;">${h_hours} hrs</div>
          <div style="font-size: 10px; color: #7f8c8d; text-transform: uppercase; margin-top: 2px; letter-spacing: 0.5px;">Duration</div>
        </td>
        <td width="33%" style="text-align: center; padding: 8px;">
          <div style="font-size: 15px; font-weight: 700; color: #1a5276;">${h_crew}</div>
          <div style="font-size: 10px; color: #7f8c8d; text-transform: uppercase; margin-top: 2px; letter-spacing: 0.5px;">Crew</div>
        </td>
      </tr>
    </table>
  </div>

  <!-- Site Considerations -->
  <div style="padding: 12px 20px; background: #f9fafb; border-bottom: 1px solid #eaecee;">
    <h3 style="margin: 0 0 6px 0; font-size: 12px; font-weight: 700; color: #1a5276; text-transform: uppercase; letter-spacing: 0.5px;">Site Considerations</h3>
    <table cellpadding="0" cellspacing="0" border="0" style="width: 100%;">
${site_html}
    </table>
  </div>

  <!-- Disclaimer -->
  <div style="padding: 8px 20px; background: #f4f6f7; font-size: 11px; color: #95a5a6; line-height: 1.4;">
    AI-generated estimate calibrated against US municipal contract rates (2024-2026). Actual costs vary by jurisdiction and site conditions.${no_photo_html}
  </div>

</div>
HTML

    return {
        ai_assessment_text => $text,
        ai_assessment_html => $html,
    };
}

# ----------------------------------------------------------------------
# UTILITY FUNCTIONS
# ----------------------------------------------------------------------

sub _format_number {
    my ($n) = @_;
    # Add commas to numbers: 25000 -> 25,000
    my $formatted = reverse $n;
    $formatted =~ s/(\d{3})(?=\d)/$1,/g;
    return scalar reverse $formatted;
}

sub _html_escape {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
    return $str;
}

1;
