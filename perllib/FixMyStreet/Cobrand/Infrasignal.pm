package FixMyStreet::Cobrand::Infrasignal;
use base 'FixMyStreet::Cobrand::Default';

use strict;
use warnings;
use FixMyStreet::MapIt;

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

1;
