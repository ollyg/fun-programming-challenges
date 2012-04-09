#!/usr/bin/perl
#
use strict;
use warnings;

use Readonly;
use Time::HiRes;

=pod

=head1 NAME

Project1

=head2 DESCRIPTION

Create two points on a 100x100 grid and have one (UAV) home in on the other
(destination location of an animal to photograph).

This is an example solution with comments to indicate parts of the program
directly relevant to the requirements listed. Those comments would not normally
be in the end program but are here for training purposes.  

=cut

Readonly my $SLEEP_INTERVAL_SEC => 0.1;
Readonly my $X_LIMIT            => 100;
Readonly my $Y_LIMIT            => 100;

print "STARTING: Map is $X_LIMIT by $Y_LIMIT\n";

my ( $dest_x, $dest_y ) = place_entity( $X_LIMIT, $Y_LIMIT );
my ( $uav_x,  $uav_y )  = place_entity( $X_LIMIT, $Y_LIMIT );

print "STARTING: UAV starts at $uav_x,$uav_y\n";
print "STARTING: destination starts at $dest_x,$dest_y\n";

my $counter = 0;
while ( $uav_x ne $dest_x or $uav_y ne $dest_y ) {

    my $x_diff = abs $uav_x - $dest_x;
    my $y_diff = abs $uav_y - $dest_y;

    if ( $x_diff > $y_diff ) {
        $uav_x = move( $uav_x, $dest_x, 'closer' );
    }
    else {
        $uav_y = move( $uav_y, $dest_y, 'closer' );
    }

    my %send = (
        'uav_x'   => $uav_x,
        'uav_y'   => $uav_y,
        'dest_x'  => $dest_x,
        'dest_y'  => $dest_y,
        'x_limit' => $X_LIMIT,
        'y_limit' => $Y_LIMIT,
        'counter' => $counter,
    );

    ( $dest_x, $dest_y ) = move_evade( \%send );

    print "MOVE: UAV moves to $uav_x,$uav_y\n";

    Time::HiRes::sleep $SLEEP_INTERVAL_SEC;
    $counter++;
}
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

=head2 move

Return UAV coordinates one step [closer to|further from] the destination

If the Absolute Value (abs) of the result of one coordinate minus the other is
the same as the result by itself, we know the answer was a positive value,
which means the UAV is at a higher coordinate number and needs to be reduce to
move closer to the destination.

Conversely if this is not true then the answer was a negative value so the UAV
is at a lower coordinate number which needs to be raised to move closer to the
destination.

There is no map boundary logic in this sub to prevent illegal positions.

=cut

sub move {
    my $myself    = shift;    # the axis coord of the object we want to change
    my $nemesis   = shift;    # the axis coord of the object we are reacting to
    my $direction = shift;

    if ( positive_difference( $myself, $nemesis ) ) {
        if ( $direction eq 'closer' ) {
            $myself--;
        }
        else {
            $myself++;
        }
    }
    else {
        if ( $direction eq 'closer' ) {
            $myself++;
        }
        else {
            $myself--;
        }
    }

    return $myself;
}

sub positive_difference {
    my $first_int  = shift;
    my $second_int = shift;

    die 'Programming error in positive_difference' if not defined $second_int;

    my $result = $first_int - $second_int;

    if ( $result != abs $result ) {

        # negative difference
        return 0;
    }

    # positive difference
    return 1;
}

=pod 

=head2 move_evade

Evade the pursuer for as long as possible wihtout exiting the map boundaries.

Stays still when cornered.

=cut

sub move_evade {
    my $data = shift;

    # [bonus requirement] Make the wild animal move away from the UAV one
    # unit every other turn (so essentially half the speed of the UAV).

    if ( $data->{counter} % 2 ) {
        return $data->{dest_x}, $data->{dest_y};
    }

    # print "DEBUG move_evade Calling that special bit\n";
    if ( !can_move_x($data) && !can_move_y($data) ) {
        print "MOVE: Animal cornered against the map edge and pursuer\n";
        return $data->{dest_x}, $data->{dest_y};
    }

    my $x_diff = abs $data->{uav_x} - $data->{dest_x};
    my $y_diff = abs $data->{uav_y} - $data->{dest_y};

    if ( $x_diff > $y_diff and can_move_x($data) ) {

        # fastest route away
        $data->{dest_x} = move( $data->{dest_x}, $data->{uav_x}, 'futher' );
    }
    elsif ( can_move_y($data) ) {

        # y is the bigger difference or we can't move in the x axis
        # either way we move in the y axis
        $data->{dest_y} = move( $data->{dest_y}, $data->{uav_y}, 'futher' );
    }
    else {

        # y is best route but we can't move in the y axis, use the slower x axis
        $data->{dest_x} = move( $data->{dest_x}, $data->{uav_x}, 'futher' );
    }

    print "MOVE: Animal moves to $data->{dest_x},$data->{dest_y}\n";
    return $data->{dest_x}, $data->{dest_y};
}

=pod 

=head2 can_move_x | can_move_y

Simplifies the logic required in working out which way a evading creature
should run.

=cut

sub can_move_x {
    my $data = shift;

    # is the uav to the right and we are against the 0 axis?
    if ( positive_difference( $data->{uav_x}, $data->{dest_x} )
        and $data->{dest_x} <= 0 )
    {

        # can't move in this axis
        return 0;
    }

    # is the uav to the left and we are against the limit of the axis?
    if ( not positive_difference( $data->{uav_x}, $data->{dest_x} )
        and $data->{dest_x} >= $data->{x_limit} )
    {
        return 0;
    }

    # otherwise we can move in this axis
    return 1;
}

sub can_move_y {
    my $data = shift;

    # is the uav to north and we are against the 0 axis?
    if ( positive_difference( $data->{uav_y}, $data->{dest_y} )
        and $data->{dest_y} <= 0 )
    {

        # can't move in this axis
        return 0;
    }

    # is the uav to the south and we are against the limit of the axis?
    if ( not positive_difference( $data->{uav_y}, $data->{dest_y} )
        and $data->{dest_y} >= $data->{y_limit} )
    {
        return 0;
    }

    # otherwise we can move in this axis
    return 1;
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
