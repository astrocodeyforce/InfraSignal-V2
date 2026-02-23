package FixMyStreet::App::Controller::Admin::PriorityZones;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => 'admin/priority_zones');

=head1 NAME

FixMyStreet::App::Controller::Admin::PriorityZones

=head1 DESCRIPTION

Admin interface for managing OSM-based priority zone configurations.
Allows admins to view, enable/disable, and edit zone type settings.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    my $user = $c->user;
    unless ($user && ($user->is_superuser || $user->has_body_permission_to('report_edit'))) {
        $c->detach('/page_error_404_not_found');
    }
    return 1;
}

sub index : Path : Args(0) {
    my ($self, $c) = @_;

    my @zones = $c->model('DB::PriorityZoneConfig')->search(
        {},
        { order_by => ['priority_level', 'label'] }
    )->all;

    # Group by priority level
    my %grouped;
    for my $zone (@zones) {
        push @{$grouped{$zone->priority_level}}, $zone;
    }

    $c->stash(
        zones => \@zones,
        grouped_zones => \%grouped,
        priority_order => ['Emergency', 'High', 'Normal', 'Low'],
        template => 'admin/priority_zones/index.html',
    );
}

sub item :PathPart('') :Chained('/') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    # Fix the chain - use the namespace path
    my $zone = $c->model('DB::PriorityZoneConfig')->find($id)
        or $c->detach('/page_error_404_not_found');
    $c->stash(zone => $zone);
}

sub edit : Path : Args(1) {
    my ($self, $c, $id) = @_;

    my $zone = $c->model('DB::PriorityZoneConfig')->find($id)
        or $c->detach('/page_error_404_not_found');

    if ($c->req->method eq 'POST') {
        my $label = $c->get_param('label') || $zone->label;
        my $priority_level = $c->get_param('priority_level') || $zone->priority_level;
        my $radius_m = $c->get_param('radius_m') || $zone->radius_m;
        my $enabled = $c->get_param('enabled') ? 1 : 0;

        # Validate priority_level
        unless (grep { $_ eq $priority_level } ('Emergency', 'High', 'Normal', 'Low')) {
            $priority_level = $zone->priority_level;
        }

        # Validate radius
        $radius_m = int($radius_m);
        $radius_m = 50  if $radius_m < 50;
        $radius_m = 2000 if $radius_m > 2000;

        $zone->update({
            label          => $label,
            priority_level => $priority_level,
            radius_m       => $radius_m,
            enabled        => $enabled,
        });

        $c->flash->{status_message} = "Zone '$label' updated successfully.";
        $c->res->redirect($c->uri_for('/admin/priority_zones'));
        $c->detach;
    }

    $c->stash(
        zone => $zone,
        priority_levels => ['Emergency', 'High', 'Normal', 'Low'],
        template => 'admin/priority_zones/edit.html',
    );
}

sub toggle : Path('toggle') : Args(1) {
    my ($self, $c, $id) = @_;

    my $zone = $c->model('DB::PriorityZoneConfig')->find($id)
        or $c->detach('/page_error_404_not_found');

    $zone->update({ enabled => $zone->enabled ? 0 : 1 });

    my $state = $zone->enabled ? 'enabled' : 'disabled';
    $c->flash->{status_message} = "Zone '" . $zone->label . "' $state.";
    $c->res->redirect($c->uri_for('/admin/priority_zones'));
    $c->detach;
}

sub reclassify : Path('reclassify') : Args(0) {
    my ($self, $c) = @_;

    require FixMyStreet::OSM::PriorityClassifier;
    my $force = $c->get_param('force') ? 1 : 0;
    my $limit = $c->get_param('limit') || 50;
    $limit = 200 if $limit > 200;

    my $count = eval {
        FixMyStreet::OSM::PriorityClassifier->reclassify_all({
            force => $force,
            limit => $limit,
        });
    };

    if ($@) {
        $c->flash->{status_message} = "Reclassification error: $@";
    } else {
        $c->flash->{status_message} = "Reclassified $count reports.";
    }

    $c->res->redirect($c->uri_for('/admin/priority_zones'));
    $c->detach;
}

__PACKAGE__->meta->make_immutable;

1;
