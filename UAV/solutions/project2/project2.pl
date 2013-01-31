#!/usr/bin/perl

=pod

=head1 NAME

Project2

=head1 USAGE

A GTK (GUI) application run directly without options

=head1 DESCRIPTION

Make a pseudo 'UAV' home in on an animal to take a photo

Or if you prefer: Make one dot home in on another

see also the original problem set out at
https://github.com/guyed/fun-programming-challenges/blob/master/UAV/2-Visualisation.tex

FIXME: segfaults when the two dots meet each other
FIXME: shows two dots, then if the simultation is advanced, the 'prey' dot is no longer drawn
FIXME: if advanced automatically without the manual button, the dots disappear and aren't drawn until the conclusio

=cut

use strict;
use warnings;

use Gtk2 '-init';
use Gnome2::Canvas;
use Time::HiRes;
use Readonly;

=pod

=head1 CONFIGURATION

Currently all configuration is static within the script

=cut

Readonly my $X_LIMIT => 100;
Readonly my $Y_LIMIT => 100;
Readonly my $SCALE   => 5 / 1;
Readonly my $X_DIVISIONS => 20;
Readonly my $Y_DIVISIONS   => 20;
Readonly my $DOT_RADIUS    => 8 / $SCALE;
Readonly my $SLEEP_SECONDS => 0.05;

Readonly my $BLACK      => Gtk2::Gdk::Color->new( 0,      0,      0, );
Readonly my $DARK_GREEN => Gtk2::Gdk::Color->new( 6_425,  18_504, 5_397, );
Readonly my $GREEN      => Gtk2::Gdk::Color->new( 12_000, 36_000, 10_000, );

Readonly my $FG_COLOR => $GREEN;
Readonly my $BG_COLOR => $BLACK;

############################################################################
#                            Main Program                                  #
############################################################################

# my ( $w_top,    $w_canvas );
my ( $uav,      $target, $complete );
my ( $uav_x,    $uav_y );
my ( $target_x, $target_y );
my $move_counter;

my $w_top = Gtk2::Window->new;
my $vbox = Gtk2::VBox->new( 0, 0 );
my $w_canvas = Gnome2::Canvas->new_aa();
my $root = $w_canvas->root();

# base window creation and control
create_widgets();

# base styling
draw_gridlines();

#draw
Gtk2->main();
    

############################################################################
#                            Subroutines                                   #
############################################################################

=pod

=head1 SUBROUTINES

=head2 create_widgets

Makes the base windows and buttons

=cut

sub create_widgets {

    $w_top->signal_connect( destroy => sub { exit } );
    $w_top->add($vbox);
    
    $w_canvas->set_pixels_per_unit($SCALE);
    $w_canvas->modify_bg( 'normal', $BG_COLOR );
    $w_canvas->set_size_request( $X_LIMIT * $SCALE, $Y_LIMIT * $SCALE, );
    $w_canvas->set_scroll_region( 0, 0, $X_LIMIT * $SCALE, $Y_LIMIT * $SCALE, );
    
    $vbox->pack_start( $w_canvas, 1, 1, 0 );

    my $quit = Gtk2::Button->new('Quit');
    $quit->signal_connect( clicked => sub { exit } );
    $vbox->pack_start( $quit, 0, 0, 0 );

    my $start_button = Gtk2::Button->new('Start Simulation');
    $start_button->signal_connect( clicked => \&start_simulation, $start_button );
    $vbox->pack_start( $start_button, 'TRUE', 'TRUE', 0 );

    my $move_button = Gtk2::Button->new('Move on simulation');
    $move_button->signal_connect( clicked => \&move_simulation, undef );
    $vbox->pack_start( $move_button, 'TRUE', 'TRUE', 0 );

    $w_top->show_all();

    return;
}

=pod

=head2 draw_gridlines

Draws a graph type grid across the canvas

=cut

sub draw_gridlines {
    # my $root = $w_canvas->root();
    my $counter;

    # draw Eastings
    $counter = 0;
    while ( $counter <= $X_DIVISIONS ) {
        my $linecolor = $DARK_GREEN;
        if ( $counter % 2 ) {
            $linecolor = $GREEN;
        }

        my $line = Gnome2::Canvas::Item->new(
            $root,
            'Gnome2::Canvas::Line',
            fill_color_gdk => $linecolor,
            width_pixels   => '1',
            points         => [
                $X_LIMIT / $X_DIVISIONS * $counter, 0,
                $X_LIMIT / $X_DIVISIONS * $counter, $Y_LIMIT,
            ],
        );
        $counter++;
    }

    # draw Northings
    $counter = 0;
    while ( $counter <= ($Y_DIVISIONS) ) {
        my $linecolor = $DARK_GREEN;
        if ( $counter % 2 ) {
            $linecolor = $GREEN;
        }

        my $line = Gnome2::Canvas::Item->new(
            $root,
            'Gnome2::Canvas::Line',
            fill_color_gdk => $linecolor,
            width_pixels   => '1',
            points         => [
                0,        $Y_LIMIT / $Y_DIVISIONS * $counter,
                $X_LIMIT, $Y_LIMIT / $Y_DIVISIONS * $counter,
            ],
        );
        $counter++;
    }

    return;
}

=pod

=head2 start_simulation

Sets things off, also clears the previous runs data

=cut

sub start_simulation {
    my $start_button = shift;

    if ( defined $uav ) {
        $uav->destroy;
    }
    if ( defined $target ) {
        $target->destroy;
    }
    if ( defined $complete ) {
        $complete->destroy;
        # FIXME: but it doesn't disappear, something wrong with my scoping
        # maybe?
    }

    ( $uav_x,    $uav_y )    = place_entity( $X_LIMIT, $Y_LIMIT );
    ( $target_x, $target_y ) = place_entity( $X_LIMIT, $Y_LIMIT );

    place_objects_on_canvas(
        {
            uav_x    => $uav_x,
            uav_y    => $uav_y,
            target_x => $target_x,
            target_y => $target_y,
        }
    );
 
    # FIXME: points dont draw on screen with this although the coordinates
    # update - something wrong with my drawing to screen
    #
    #while($uav_x ne $target_x or $uav_y ne $target_y){
    #    move_simulation();
    #    Time::HiRes::sleep($SLEEP_SECONDS);
    #}

    return;
}

=pod

=head2 place_objects_on_canvas

Put the starting dots down for the UAV and target

=cut

sub place_objects_on_canvas {
    my $data = shift;
    # my $root = $w_canvas->root();

    $uav = Gnome2::Canvas::Item->new(
        $root, 'Gnome2::Canvas::Ellipse',
        x1            => $data->{uav_x} - $DOT_RADIUS,
        y1            => $data->{uav_y} - $DOT_RADIUS,
        x2            => $data->{uav_x} + $DOT_RADIUS,
        y2            => $data->{uav_y} + $DOT_RADIUS,
        fill_color    => 'green',
        outline_color => 'black',
        width_pixels  => '1',
    );

    $target = Gnome2::Canvas::Item->new(
        $root, 'Gnome2::Canvas::Ellipse',
        x1            => $data->{target_x} - $DOT_RADIUS,
        y1            => $data->{target_y} - $DOT_RADIUS,
        x2            => $data->{target_x} + $DOT_RADIUS,
        y2            => $data->{target_y} + $DOT_RADIUS,
        fill_color    => 'red',
        outline_color => 'black',
        width_pixels  => '1',
    );

    return;
}

=pod

=head2 move_simulation

Do the calculations to move the UAV about

=cut

sub move_simulation {

    if ( $uav_x ne $target_x or $uav_y ne $target_y ) {

        # do the calculation
        my $x_diff = abs $uav_x - $target_x;
        my $y_diff = abs $uav_y - $target_y;

        if ( $x_diff > $y_diff ) {
            $uav_x = move_closer( $uav_x, $target_x, 'x' );
        }
        else {
            $uav_y = move_closer( $uav_y, $target_y, 'y' );
        }

        $uav->request_update;
        print "MOVE: UAV: $uav_x,$uav_y Target: $target_x, $target_y\n";
    }

    # not an elseif as the move above might result in the below (or the
    # condition might already exist).

    if ( $uav_x eq $target_x and $uav_y eq $target_y ) {
        print "FINISH: UAV at $uav_x,$uav_y target at $target_x,$target_y\n";

        $uav->destroy;
        $target->destroy;

        $complete = Gnome2::Canvas::Item->new(
            $root, 'Gnome2::Canvas::Ellipse',
            x1            => $uav_x - $DOT_RADIUS,
            y1            => $uav_y - $DOT_RADIUS,
            x2            => $uav_x + $DOT_RADIUS,
            y2            => $uav_y + $DOT_RADIUS,
            fill_color    => 'blue',
            outline_color => 'black',
            width_pixels  => '1',
        );
    }
    
    my %send = (
        'uav_x'   => $uav_x,
        'uav_y'   => $uav_y,
        'dest_x'  => $target_x,
        'dest_y'  => $target_y,
        'x_limit' => $X_LIMIT,
        'y_limit' => $Y_LIMIT,
        'counter' => $move_counter,
    );

    ( $target_x, $target_y ) = move_evade( \%send );
    $target->move( $target_x, $target_y );

    $move_counter++;
}

=pod

    return;
}

=pod

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
    my $location    = shift;
    my $destination = shift;
    my $axis        = shift;

    my $offset = 0;
    my $result = $location - $destination;

    if ( $result == abs $result ) {

        # we have a positive offset we need to reduce
        $offset--;
    }
    else {

        # we have a negative offset to reduce
        $offset++;
    }

    my $newlocation = $location + $offset;

    if ( $axis eq 'x' ) {
        $uav->move( $offset, 0 );
    }
    elsif ( $axis eq 'y' ) {
        $uav->move( 0, $offset );
    }

    return $newlocation;
}

=pod

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

FIXME: segfaults when the two dots meet each other
FIXME: shows two dots, then if the simultation is advanced, the 'prey' dot is no longer drawn
FIXME: if advanced automatically without the manual button, the dots disappear and aren't drawn until the conclusio

=head1 AUTHOR

Guy Edwards <guyjohnedwards@gmail.com>

=head1 LICENSE AND COPYRIGHT

I don't believe this is script is big or unique enough to warrant copyright so
I hereby notify that I disown any copyright interest in this individual
script. This script can be regarded as public domain.
