package FixMyStreet::Cobrand::Infrasignal;
use base 'FixMyStreet::Cobrand::Default';

use strict;
use warnings;
use FixMyStreet::MapIt;
use FixMyStreet::AIAssessment;

=head1 NAME

FixMyStreet::Cobrand::Infrasignal

=head1 DESCRIPTION

Cobrand for InfraSignal (US-based FixMyStreet instance).
Overrides admin_fetch_all_bodies to avoid loading 28K+ bodies at once.
Overrides area fetching to avoid slow global MapIt calls.

=cut

# Return a non-empty list so fetch_all_bodies skips its fallback that
# would otherwise load all 28K bodies from the DB.
# Our admin templates use AJAX cascading state→body dropdowns instead,
# so the 'bodies' stash variable is never iterated in our cobrand templates.
sub admin_fetch_all_bodies {
    return (0);  # truthy list (length 1) prevents the fallback query
}

# Override the area_types used for admin to prevent fetching all global areas.
# Instead, we return an empty type list and handle areas via the hook below.
sub area_types_for_admin {
    return [];
}

# Instead of fetching all global areas (which times out), only fetch the
# areas that the body currently covers, plus do a targeted lookup if editing.
sub add_extra_areas_for_admin {
    my ($self, $areas) = @_;
    $areas ||= {};

    my $c = $self->{c};
    my $body = $c->stash->{body};
    return $areas unless $body;

    # Fetch the specific areas this body covers
    my @body_area_ids = map { $_->area_id } $body->body_areas->all;
    for my $area_id (@body_area_ids) {
        next if $areas->{$area_id};
        my $area_data = eval { FixMyStreet::MapIt::call('area', $area_id) };
        next unless $area_data && ref $area_data eq 'HASH' && $area_data->{id};
        $areas->{$area_id} = $area_data;
    }

    return $areas;
}

# Restrict the "Pick your local authority" dropdown on /reports to only bodies
# that have at least one report, instead of listing all 28K+ bodies.
sub reports_hook_restrict_bodies_list {
    my ($self, $bodies) = @_;

    # Collect all body IDs that have reports. bodies_str can be comma-separated.
    my @rows = FixMyStreet::DB->resultset('Problem')->search(
        { bodies_str => { '!=' => undef } },
        { columns => ['bodies_str'], distinct => 1 }
    )->all;
    my %has_reports;
    for my $row (@rows) {
        for my $id (split /,/, $row->bodies_str) {
            $has_reports{$id} = 1;
        }
    }

    # Bodies may be blessed objects or plain hashrefs (from ->translated chain)
    my @filtered = grep {
        my $id = ref($_) && ref($_) eq 'HASH' ? $_->{id} : eval { $_->id };
        $id && $has_reports{$id};
    } @$bodies;
    return \@filtered;
}

# After a new report is inserted, ensure the assigned body has default
# response priorities. This way, when a body receives its first-ever report,
# the 4 standard priorities (Emergency, High, Normal, Low) are auto-created.
sub report_new_munge_after_insert {
    my ($self, $report) = @_;

    my $bodies_str = $report->bodies_str;
    return unless $bodies_str;

    my @body_ids = split /,/, $bodies_str;
    my $schema = $report->result_source->schema;

    my @default_priorities = (
        { name => 'Emergency', description => 'Immediate safety hazard' },
        { name => 'High',      description => 'Needs attention within 24 hours' },
        { name => 'Normal',    description => 'Standard response time' },
        { name => 'Low',       description => 'Non-urgent' },
    );

    for my $body_id (@body_ids) {
        # Check if this body already has priorities
        my $count = $schema->resultset('ResponsePriority')->search({
            body_id => $body_id,
        })->count;

        next if $count > 0;

        # Create default priorities for this body
        for my $p (@default_priorities) {
            $schema->resultset('ResponsePriority')->create({
                body_id     => $body_id,
                name        => $p->{name},
                description => $p->{description},
            });
        }
    }
}

# Disable the creation graph link — the PNG is not generated for this site
sub admin_show_creation_graph { 0 }

# Enable duplicate detection: when a user creates a new report, the system
# searches for existing nearby reports in the same category and shows them
# as "Already been reported?" suggestions before the report is submitted.
sub suggest_duplicates { 1 }

# Configurable nearby distances (in metres) for duplicate suggestions.
# 'suggestions' = distance shown to public users during new report creation
# 'inspector'   = distance shown to admin/inspectors when marking duplicates
sub nearby_distances { {
    suggestions => 500,   # 500m radius for public duplicate suggestions
    inspector   => 1500,  # 1500m radius for inspector duplicate lookup
} }

# Add "Duplicate Reports" to admin sidebar navigation.
# Extends the default admin_pages with our custom page.
sub admin_pages {
    my $self = shift;
    my $pages = $self->SUPER::admin_pages();

    # Add Duplicate Reports tab (visible to users who can edit reports)
    my $user = $self->{c}->user;
    if ($user && ($user->is_superuser || $user->has_body_permission_to('report_edit'))) {
        $pages->{duplicate_reports} = [ 'Duplicate Reports', 2.5 ];
    }

    return $pages;
}

# Cookie-based language override for the language switcher UI.
# Supports ?lang=<code> query parameter which sets a persistent cookie,
# or reads from previously set cookie. Falls back to browser negotiation.
sub language_override {
    my $self = shift;
    my $c = $self->{c};
    return unless $c;

    # Check for ?lang= query parameter — set cookie and use it
    my $lang_param = $c->req->param('lang');
    if ($lang_param) {
        $c->res->cookies->{lang} = {
            value   => $lang_param,
            expires => '+1y',
            path    => '/',
        };
        return $lang_param;
    }

    # Read from existing cookie
    my $lang_cookie = $c->req->cookie('lang');
    return $lang_cookie->value if $lang_cookie;

    return;
}

# After template variables are built for the report email, call the AI
# assessment engine to classify the damage and look up deterministic
# cost/time/crew data.  Results are injected as template variables
# ai_assessment_text and ai_assessment_html.
sub process_additional_metadata_for_email {
    my ($self, $report, $h) = @_;

    # Build context hash with location and environmental data
    my %context = (
        closest_address => $h->{closest_address} || '',
        latitude        => $report->latitude,
        longitude       => $report->longitude,
    );

    my $assessment = eval {
        FixMyStreet::AIAssessment->generate_assessment($report, \%context);
    };
    if ($@ || !$assessment) {
        warn "AIAssessment hook error: " . ($@ || 'empty result') . "\n";
        $h->{ai_assessment_text} = '';
        $h->{ai_assessment_html} = '';
        return;
    }

    $h->{ai_assessment_text} = $assessment->{ai_assessment_text} || '';
    $h->{ai_assessment_html} = $assessment->{ai_assessment_html} || '';
}

1;
