#!/usr/bin/perl
#
use strict;
use warnings;

=pod

=head1 NAME

Project1

=head2 DESCRIPTION

Create two points on a 100x100 grid and have one (UAV) home in on the other
(destination location).

This is an example solution with comments to indicate parts of the program
directly relevant to the reuirements listed. Those comments would not normally
be in the end program but are here for training purposes.  

=cut

my $SLEEP_INTERVAL_SEC=1;

# [requirement] Write code to create a 100x100 grid two dimensional grid.
my $range_x = 100;
my $range_y = 100;

print "STARTING: Map is $range_x by $range_y\n";

# [requirement] When the program starts, place a destination location at
# random on the grid (at a integer point, e.g. 84x34 not 84.321x34.123)
my ( $dest_x, $dest_y ) = place_entity( $range_x, $range_y );

# [requirement] Also place a UAV starting position at random on the grid (at a
# integer point)
my ( $uav_x,    $uav_y )    = place_entity( $range_x, $range_y );

# [requirement] When the program starts, print both the UAV position and the
# destination position
print "STARTING: UAV starts at $uav_x,$uav_y\n";
print "STARTING: destination starts at $dest_x,$dest_y\n";

# [requirement] With each iteration of the program, make the UAV move one X or
# Y coordinate closer to the destination
while ( $uav_x ne $dest_x or $uav_y ne $dest_y ) {

    my $x_diff = abs $uav_x - $dest_x;
    my $y_diff = abs $uav_y - $dest_y;

    if ( $x_diff > $y_diff ) {
        $uav_x = move_closer( $uav_x, $dest_x );
    }
    else {
        $uav_y = move_closer( $uav_y, $dest_y );
    }
    # [requirement] Print the UAV position at each step
    print "MOVE: UAV moves to $uav_x,$uav_y\n";

    # [requirement] Introduce a configurable delay in the code between each
    # iteration so that a user can read the printed output before the next
    # line appears
    sleep $SLEEP_INTERVAL_SEC;

}
# [requirement] Make the program stop when the UAV reaches the destination
#
print "FINISH: UAV at $uav_x,$uav_y destination at $dest_x,$dest_y\n";

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

Return UAV coordinates closer to the destination

If the Absolute Value (abs) of the result of one coordinate minus the other is
the same as the result by itself, we know the answer was a positive value,
which means the UAV is at a higher coordinate number and needs to be reduce to
move closer to the destination.

Conversely if this is not true then the answer was a negative value so the UAV
is at a lower coordinate number which needs to be raised to move closer to the
destination.

=cut

sub move_closer {
    my $location = shift;
    my $destination   = shift;

    my $result = $location - $destination;

    if ( $result == abs $result ) {
        $location--;
    }
    else {
        $location++;
    }

    return $location;
}

=head1 BUGS AND LIMITATIONS

* I've deliberatly left out some beneficial feature to keep the code
simple (such as a higher resolution timer for the sleep interval that can do
sub second intervals).

=head1 AUTHOR

Guy Edwards <guyjohnedwards@gmail.com>

=head1 LICENSE AND COPYRIGHT

I don't believe this is script is big or unique enough to warrant copyright so
I hereby notify that I disown any copyright interest in this individual
script. This script can be regarded as public domain.
