package FixMyStreet::App::Controller::Admin::DuplicateReports;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

# Force the URL namespace to use underscore: /admin/duplicate_reports
__PACKAGE__->config(namespace => 'admin/duplicate_reports');

=head1 NAME

FixMyStreet::App::Controller::Admin::DuplicateReports

=head1 DESCRIPTION

Admin page that shows potential duplicate reports detected by geographic
proximity + same category.  Groups are ordered by distance (closest first).

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $radius = $c->get_param('radius') || 500;   # metres
    $radius = 2000 if $radius > 2000;
    $radius = 50   if $radius < 50;
    $c->stash->{radius} = $radius;

    my $category_filter = $c->get_param('category') || '';
    $c->stash->{category_filter} = $category_filter;

    my $state_filter = $c->get_param('state') || '';
    $c->stash->{state_filter} = $state_filter;

    # Build the duplicate-pair query using Haversine formula
    # Returns pairs (a.id < b.id) within $radius metres sharing the same category
    my $dbh = $c->model('DB::Problem')->result_source->storage->dbh;

    my $sql = q{
        SELECT
            a.id        AS id_a,
            a.title     AS title_a,
            a.detail    AS detail_a,
            a.state     AS state_a,
            a.category  AS category,
            a.latitude  AS lat_a,
            a.longitude AS lng_a,
            a.created   AS created_a,
            a.photo     AS photo_a,
            b.id        AS id_b,
            b.title     AS title_b,
            b.detail    AS detail_b,
            b.state     AS state_b,
            b.latitude  AS lat_b,
            b.longitude AS lng_b,
            b.created   AS created_b,
            b.photo     AS photo_b,
            ROUND(
                (6371000 * acos(
                    LEAST(1.0,
                        sin(radians(a.latitude)) * sin(radians(b.latitude))
                      + cos(radians(a.latitude)) * cos(radians(b.latitude))
                        * cos(radians(a.longitude - b.longitude))
                    )
                ))::numeric, 0
            ) AS distance_m
        FROM problem a
        JOIN problem b
          ON a.id < b.id
         AND a.category = b.category
         AND a.latitude IS NOT NULL AND a.longitude IS NOT NULL
         AND b.latitude IS NOT NULL AND b.longitude IS NOT NULL
        WHERE
            6371000 * acos(
                LEAST(1.0,
                    sin(radians(a.latitude)) * sin(radians(b.latitude))
                  + cos(radians(a.latitude)) * cos(radians(b.latitude))
                    * cos(radians(a.longitude - b.longitude))
                )
            ) < ?
    };

    my @params = ($radius);

    if ($category_filter) {
        $sql .= " AND a.category = ?";
        push @params, $category_filter;
    }

    if ($state_filter && $state_filter eq 'open') {
        $sql .= " AND a.state NOT IN ('hidden','closed','fixed','fixed - council','fixed - user','duplicate')";
        $sql .= " AND b.state NOT IN ('hidden','closed','fixed','fixed - council','fixed - user','duplicate')";
    } elsif (!$state_filter || $state_filter eq '') {
        # Default: show only open reports (exclude duplicate state too)
        $sql .= " AND a.state NOT IN ('hidden','closed','fixed','fixed - council','fixed - user','duplicate')";
        $sql .= " AND b.state NOT IN ('hidden','closed','fixed','fixed - council','fixed - user','duplicate')";
    } elsif ($state_filter ne 'all') {
        $sql .= " AND (a.state = ? OR b.state = ?)";
        push @params, $state_filter, $state_filter;
    }

    $sql .= " ORDER BY distance_m ASC, a.created DESC LIMIT 200";

    my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @params);

    # Group into duplicate clusters using union-find (closures to share lexicals)
    my %parent;
    my %rank;
    my $find;
    $find = sub {
        my ($id) = @_;
        $parent{$id} = $id unless exists $parent{$id};
        if ($parent{$id} ne $id) {
            $parent{$id} = $find->($parent{$id});  # path compression
        }
        return $parent{$id};
    };
    my $union = sub {
        my ($a, $b) = @_;
        my $ra = $find->($a);
        my $rb = $find->($b);
        return if $ra eq $rb;
        $rank{$ra} ||= 0;
        $rank{$rb} ||= 0;
        if ($rank{$ra} < $rank{$rb}) { $parent{$ra} = $rb; }
        elsif ($rank{$ra} > $rank{$rb}) { $parent{$rb} = $ra; }
        else { $parent{$rb} = $ra; $rank{$ra}++; }
    };

    # Collect all report info and edges
    my %reports;
    my @edges;
    for my $row (@$rows) {
        $union->($row->{id_a}, $row->{id_b});
        push @edges, {
            id_a => $row->{id_a},
            id_b => $row->{id_b},
            distance_m => $row->{distance_m},
        };
        for my $side (qw(a b)) {
            my $id = $row->{"id_$side"};
            next if $reports{$id};
            my $photo_ref = $row->{"photo_$side"};
            $reports{$id} = {
                id        => $id,
                title     => $row->{"title_$side"},
                detail    => $row->{"detail_$side"},
                state     => $row->{"state_$side"},
                category  => $row->{category},
                latitude  => $row->{"lat_$side"},
                longitude => $row->{"lng_$side"},
                created   => $row->{"created_$side"},
                has_photo => $photo_ref ? 1 : 0,
            };
        }
    }

    # Build groups
    my %groups;
    for my $id (keys %reports) {
        my $root = $find->($id);
        push @{$groups{$root}}, $reports{$id};
    }

    # Sort groups: closest distance first, then by group size
    my @duplicate_groups;
    for my $root (keys %groups) {
        my @members = sort { $a->{id} <=> $b->{id} } @{$groups{$root}};
        # Find min distance within this group
        my $min_dist = 999999;
        for my $edge (@edges) {
            if ($find->($edge->{id_a}) eq $root) {
                $min_dist = $edge->{distance_m} if $edge->{distance_m} < $min_dist;
            }
        }
        push @duplicate_groups, {
            reports      => \@members,
            count        => scalar @members,
            min_distance => $min_dist,
            category     => $members[0]->{category},
            report_ids   => join(',', map { $_->{id} } @members),
        };
    }
    @duplicate_groups = sort {
        $a->{min_distance} <=> $b->{min_distance}
        || $b->{count} <=> $a->{count}
    } @duplicate_groups;

    $c->stash->{duplicate_groups} = \@duplicate_groups;
    $c->stash->{total_pairs} = scalar @$rows;
    $c->stash->{total_groups} = scalar @duplicate_groups;

    # Get distinct categories for filter dropdown
    my $cats = $dbh->selectcol_arrayref(
        "SELECT DISTINCT category FROM problem WHERE category IS NOT NULL ORDER BY category"
    );
    $c->stash->{categories} = $cats || [];

    $c->forward('/auth/get_csrf_token');
    $c->stash->{template} = 'admin/duplicate_reports.html';
}

=head2 mark_duplicate

POST action to mark a report as duplicate of another.

=cut

sub mark_duplicate : Path('mark') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/auth/check_csrf_token');

    my $report_id    = $c->get_param('report_id');
    my $duplicate_of = $c->get_param('duplicate_of');

    if ($report_id && $duplicate_of && $report_id != $duplicate_of) {
        my $report = $c->model('DB::Problem')->find($report_id);
        if ($report) {
            $report->set_duplicate_of($duplicate_of);
            $report->state('duplicate');
            $report->update;

            $c->forward('/admin/log_edit', [
                $report_id, 'problem',
                "Marked as duplicate of #$duplicate_of via Duplicate Reports page"
            ]);
        }
    }

    $c->res->redirect($c->uri_for('/admin/duplicate_reports'));
}

=head2 dismiss

POST action to dismiss a duplicate group (sets metadata so it won't show again).

=cut

sub dismiss : Path('dismiss') : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/auth/check_csrf_token');

    my @ids = $c->get_param('report_ids') ? split(/,/, $c->get_param('report_ids')) : ();
    for my $id (@ids) {
        my $report = $c->model('DB::Problem')->find($id);
        if ($report) {
            $report->set_extra_metadata(duplicate_dismissed => 1);
            $report->update;
        }
    }

    $c->res->redirect($c->uri_for('/admin/duplicate_reports'));
}

__PACKAGE__->meta->make_immutable;

1;
