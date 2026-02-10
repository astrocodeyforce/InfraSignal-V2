package FixMyStreet::Cobrand::Infrasignal;
use parent 'FixMyStreet::Cobrand::Default';

use strict;
use warnings;

=head1 NAME

FixMyStreet::Cobrand::Infrasignal - InfraSignal cobrand

=head1 DESCRIPTION

The InfraSignal cobrand configuration.

=head1 METHODS

=over

=item pin_colour

Returns red for all reports. This determines the color of the map pin marker
displayed for each report on the map.

=back

=cut

sub pin_colour {
    my ( $self, $p, $context ) = @_;
    return 'red';
}

1;
