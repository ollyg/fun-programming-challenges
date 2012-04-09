#!/usr/bin/perl
#
use strict;
use warnings;

=pod

=head1 NAME

Project1

=head2 DESCRIPTION

Create two points on a 100x100 grid and have one (UAV) home in on the other
(target).

=cut

my $range_x = 100;
my $range_y = 100;

print "STARTING: Map is $range_x by $range_y\n";

my ( $uav_x,    $uav_y )    = place_entity( $range_x, $range_y );
my ( $target_x, $target_y ) = place_entity( $range_x, $range_y );

print "STARTING: UAV starts at $uav_x,$uav_y\n";
print "STARTING: target starts at $target_x,$target_y\n";

while ( $uav_x ne $target_x or $uav_y ne $target_y ) {

    my $x_diff = abs $uav_x - $target_x;
    my $y_diff = abs $uav_y - $target_y;

    if ( $x_diff > $y_diff ) {
        $uav_x = move_closer( $uav_x, $target_x );
    }
    else {
        $uav_y = move_closer( $uav_y, $target_y );
    }
    print "MOVE: UAV moves to $uav_x,$uav_y\n";

}
print "FINISH: UAV at $uav_x,$uav_y target at $target_x,$target_y\n";

=pod

=head1 SUBROUTINES

=head2 place_entitly

Create a pseudo random starting position within the x and y limits provided

=cut

sub place_entity {
    my $x_limit = shift;
    my $y_limit = shift;

    my $x_return = int rand $x_limit;
    my $y_return = int rand $y_limit;

    return $x_return, $y_return;
}

=pod

=head2 move_closer

Return UAV coordinates closer to the target

If the Absolute Value (abs) of the result of one coordinate minus the other is
the same as the result by itself, we know the answer is positive, which means
the UAV is at a higher coordinate number and needs to be reduce to move
closer.

Conversely if this is not true then the UAV is at a lower coordinate number
which needs to be raised to move closer.

=cut

sub move_closer {
    my $location = shift;
    my $target   = shift;

    my $result = $location - $target;

    if ( $result == abs $result ) {
        $location--;
    }
    else {
        $location++;
    }

    return $location;
}

