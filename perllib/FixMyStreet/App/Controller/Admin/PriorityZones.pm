package FixMyStreet::App::Controller::Admin::PriorityZones;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => 'admin/priority_zones');

=head1 NAME

FixMyStreet::App::Controller::Admin::PriorityZones

=head1 DESCRIPTION

Admin interface for managing OSM-based priority zone configurations.

Two tiers:

=over 4

=item * Superusers manage the global default zones (body_id NULL) exactly as
before, and can see any per-body overrides that exist.

=item * Body staff (report_inspect permission) see the effective config for
their own body: their overrides where present, global defaults otherwise.
Editing or toggling a global zone as staff copy-on-writes an override row for
their body (body_id set); the global row is never modified. Reclassification
for staff is restricted to their own body's reports.

=back

=cut

sub auto :Private {
    my ($self, $c) = @_;
    my $user = $c->user;
    unless ($user && ($user->is_superuser || $user->has_body_permission_to('report_inspect'))) {
        $c->detach('/page_error_404_not_found');
    }
    # For body staff, everything below is scoped to this body.
    $c->stash->{pz_body} = (!$user->is_superuser && $user->from_body) ? $user->from_body : undef;
    return 1;
}

# For staff: effective zone list (their override or the global default per
# tag). For superusers: the global zones, as before.
sub _effective_zones {
    my ($self, $c) = @_;
    my $body = $c->stash->{pz_body};

    my $rs = $c->model('DB::PriorityZoneConfig');
    if (!$body) {
        return [ $rs->search({ body_id => undef }, { order_by => ['priority_level', 'label'] })->all ];
    }

    my %by_tag;
    for my $zone ($rs->search({ body_id => [ undef, $body->id ] })->all) {
        my $tag = $zone->osm_key . '=' . $zone->osm_value;
        if (!$by_tag{$tag} || (defined $zone->body_id && !defined $by_tag{$tag}->body_id)) {
            $by_tag{$tag} = $zone;
        }
    }
    return [ sort { $a->priority_level cmp $b->priority_level || ($a->label || '') cmp ($b->label || '') } values %by_tag ];
}

# Resolve a zone id for the current user. Staff may load global rows (as
# read-only templates) and their own body's overrides — never another body's.
sub _find_zone_for_user {
    my ($self, $c, $id) = @_;
    my $zone = $c->model('DB::PriorityZoneConfig')->find($id)
        or $c->detach('/page_error_404_not_found');
    my $body = $c->stash->{pz_body};
    if ($body && defined $zone->body_id && $zone->body_id != $body->id) {
        $c->detach('/page_error_404_not_found');
    }
    return $zone;
}

# Copy-on-write: when staff modify a global zone, find or create their body's
# override row for the same tag. Their own override rows are used directly.
sub _override_for_staff {
    my ($self, $c, $zone) = @_;
    my $body = $c->stash->{pz_body};
    return $zone unless $body;             # superuser edits the row directly
    return $zone if defined $zone->body_id; # already their override (_find_zone_for_user enforced ownership)

    return $c->model('DB::PriorityZoneConfig')->find_or_create({
        osm_key        => $zone->osm_key,
        osm_value      => $zone->osm_value,
        body_id        => $body->id,
        label          => $zone->label,
        priority_level => $zone->priority_level,
        radius_m       => $zone->radius_m,
        enabled        => $zone->enabled,
    });
}

sub index : Path : Args(0) {
    my ($self, $c) = @_;

    # The reclassify/toggle forms POST a CSRF token; stash one for the template
    $c->forward('/auth/get_csrf_token');

    my $zones = $self->_effective_zones($c);

    # Group by priority level
    my %grouped;
    for my $zone (@$zones) {
        push @{$grouped{$zone->priority_level}}, $zone;
    }

    # Superusers also see existing per-body overrides (read-only list).
    my @overrides;
    if (!$c->stash->{pz_body}) {
        @overrides = $c->model('DB::PriorityZoneConfig')->search(
            { body_id => { '!=' => undef } },
            { order_by => ['body_id', 'priority_level', 'label'], prefetch => 'body' }
        )->all;
    }

    $c->stash(
        zones => $zones,
        grouped_zones => \%grouped,
        body_overrides => \@overrides,
        priority_order => ['Emergency', 'High', 'Normal', 'Low'],
        template => 'admin/priority_zones/index.html',
    );
}

sub edit : Path : Args(1) {
    my ($self, $c, $id) = @_;

    my $zone = $self->_find_zone_for_user($c, $id);
    $c->forward('/auth/get_csrf_token');

    if ($c->req->method eq 'POST') {
        $c->forward('/auth/check_csrf_token');

        # Staff edits land on their body's override row, never the global one
        $zone = $self->_override_for_staff($c, $zone);

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

        my $scope = $zone->body_id ? " (override for " . $c->stash->{pz_body}->name . ")" : "";
        $c->flash->{status_message} = "Zone '$label' updated successfully$scope.";
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

    # Require POST to prevent CSRF via GET (e.g. hidden <img> tags)
    unless ($c->req->method eq 'POST') {
        $c->res->redirect($c->uri_for('/admin/priority_zones'));
        $c->detach;
    }
    $c->forward('/auth/check_csrf_token');

    my $zone = $self->_find_zone_for_user($c, $id);
    my $was_enabled = $zone->enabled;
    $zone = $self->_override_for_staff($c, $zone);

    $zone->update({ enabled => $was_enabled ? 0 : 1 });

    my $state = $zone->enabled ? 'enabled' : 'disabled';
    $c->flash->{status_message} = "Zone '" . ($zone->label || $zone->osm_value) . "' $state.";
    $c->res->redirect($c->uri_for('/admin/priority_zones'));
    $c->detach;
}

sub reclassify : Path('reclassify') : Args(0) {
    my ($self, $c) = @_;

    # Require POST to prevent CSRF via GET
    unless ($c->req->method eq 'POST') {
        $c->res->redirect($c->uri_for('/admin/priority_zones'));
        $c->detach;
    }
    $c->forward('/auth/check_csrf_token');

    require FixMyStreet::OSM::PriorityClassifier;
    my $force = $c->get_param('force') ? 1 : 0;
    my $limit = $c->get_param('limit') || 50;
    $limit = 200 if $limit > 200;

    my $count = eval {
        FixMyStreet::OSM::PriorityClassifier->reclassify_all({
            force => $force,
            limit => $limit,
            # Staff reclassification only touches their own body's reports
            $c->stash->{pz_body} ? (body_id => $c->stash->{pz_body}->id) : (),
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
