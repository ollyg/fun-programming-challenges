#!/usr/bin/perl

=pod

=head1 NAME

Project2

=head1 USAGE

A GTK (GUI) application run directly without options

=head1 DESCRIPTION

Make a pseudo 'UAV' home in on a map reference to take a photo

Or if you prefer: Make one dot home in on another

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

=head1 INCOMPATIBILITIES

None known

=head1 BUGS AND LIMITATIONS

* You have to click a button to move the simulation forward
* Quit sometimes results in a segmentation fault for an unknown reason.
* Completed run blue dot doesn't disappear on the next run. I could be
dishonest and claim this is an intentional feature but Santa would know.

=head1 AUTHOR

Guy Edwards <guyjohnedwards@gmail.com>

=head1 LICENSE AND COPYRIGHT

I don't believe this is script is big or unique enough to warrant copyright, I
hereby notify that I disown any copyright interest in this individual script,
this script can be regarded as public domain.
