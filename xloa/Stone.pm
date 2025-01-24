# -*- perl -*-
#
# Copyright (C) 2000 Christian Weninger and Jens Thoms Törring
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
############################################################################

# Package that creates, draws and moves the stones on the board

package Stone;
use strict;
use IPC::Semaphore;
use Tk;
use Board;
use MBox;
use CBox;
use MList;


# Global data to be used by all stone objects, set them with
# &Stone::set( key => value );
# The values given are here are not relevant and are replaced by the
# initialistation routines, so apply changes to %defaults in Init.pm!

my %opt = (
	canvas          => undef,
	board           => undef,
	stonecolor1     => 'black',
	stonecolor2     => 'white',
	movesarrowcolor => 'blue',
);

# Each stone object has the following properties set (some only temporary)
#
#     ID            ID of stone in board canvas
#     color         color of stone, either "white" or "black"
#     pos           position in format /^[a-h][1-8]$/i
#     xc            current center x position
#     yc            center y position
#     xul           upper left corner x position
#     yul           upper left corner y position
#     xlr           lower right corner x position
#     ylr           lower right corner y position
#     cur_x         x position while dragging
#     cur_y         y position while dragging
#     is_arrows     exists while move arrows are shown


#---------------------
# Creates a new stone - must be called with two arguments, the position of
# the stone (in the form /^[a-h][1-8]$/i) and the color ("white" or "black").

sub new {

	bless my $self = { }, shift;
	$self->init( @_ );
	return $self;
}

#---------------------

sub init {

	my ( $self, $pos, $color ) = @_;

	unless ( defined $pos ) {
		&main::suicide;
		die "Missing position for stone" ;
	}
	unless ( defined $color ) {
		&main::suicide;
		die "Missing color for stone" ;
	}

	$self->pos( $pos );
	$self->color( $color );
	$self->coord( Board->get_coords( $self->pos ) );
	$self->draw;
}

#---------------------
# Deletes a stone

sub destroy {

	my $self = shift;

	if ( exists $self->{ 'is_arrows' } ) {
		$opt{ canvas }->delete( 'move_arrows' );
		delete $self->{ 'is_arrows' };
	}
	$opt{ canvas }->delete( $self->{ ID } ) if defined $self->{ ID };
	return undef %$self;
}

#---------------------

sub draw {

	my ( $self, $is_flash ) = @_;

	# Delete stone from canvas if it has already been drawn (after removing the
	# moves arrows because the callback binding for doing so is also deleted)

	if ( exists $self->{ 'is_arrows' } ) {
		$opt{ canvas }->delete( 'move_arrows' );
		delete $self->{ 'is_arrows' };
	}
	$opt{ canvas }->delete( $self->{ ID } ) if defined $self->{ ID };

	# Get the colors right

	my @col = ( $opt{ stonecolor1 }, $opt{ stonecolor2 } );
	push @col, shift @col if $self->color =~ /^white$/i;     # swap for white

	# Draw it

	$self->{ ID }= $opt{ canvas }->create( 'oval',
										   ( $self->coord )[ 2..5 ],
										   '-fill' => $col[ 0 ],
										   '-outline' => $col[ 1 ],
										   '-width' => 1
										 );
	$opt{ canvas }->update;

	# Flash the move by lowering and raising the stone relative to its field

	if ( $is_flash and Menus->get( 'flash' ) ) {
		my $field_ID = $opt{ board }->get_field_ID( $self->{ pos } );

		for my $i ( 0..$opt{ flashes } ) {
			select( undef, undef, undef, $opt{ flashtime } );
			$opt{ canvas }->lower( $self->{ ID }, $field_ID );
			$opt{ canvas }->update;
			select( undef, undef, undef, $opt{ flashtime } );
			$opt{ canvas }->lower( $field_ID, $self->{ ID } );
			$opt{ canvas }->update;
		}
	}

	# Set the appropriate handlers

	$opt{ canvas }->bind( $self->{ ID },
						  '<ButtonPress-1>' => [ \&pick_up, $self ] );
	$opt{ canvas }->bind( $self->{ ID },
						  '<ButtonPress-3>' => [ \&show_moves, $self, 1 ] );
	$opt{ canvas }->bind( $self->{ ID },
						  '<ButtonRelease-3>' => [ \&show_moves, $self ] );
	return $self->{ ID };
}

#---------------------
# Sets or returns the color of a stone (not the color it's actually drawn
# with but either "black" or "white" ;-)

sub color {

	my ( $self, $color ) = @_;

 	return $self->{ color } unless defined $color;
	if ( $color !~ /^(white)|(black)$/i ) {
		&main::suicide;
		die "Invalid color for $self: '$color'";
	}
	return $self->{ color } = $color;
}

#---------------------
# Sets or returns the position of a stone

sub pos {

	my ( $self, $pos ) = @_;

 	return $self->{ pos } unless defined $pos;
	if ( $pos !~ /^[a-h][1-8]$/i ) {
		&main::suicide;
		die "Invalid position for $self: '$pos'";
	}
	return $self->{ pos } = $pos;
}

#---------------------
# Sets or returns the coordinates of a stone (center as well as upper left
# and lower right corner coordinates)

sub coord {

	my $self = shift;

	return ( $self->{ xc  }, $self->{ yc  },
			 $self->{ xul }, $self->{ yul },
			 $self->{ xlr }, $self->{ ylr } ) if @_ == 0;

	return ( $self->{ xc  }, $self->{ yc  },
			 $self->{ xul }, $self->{ yul },
			 $self->{ xlr }, $self->{ ylr } ) = @_;
}

#---------------------
# Callback for ButtonPress-1 events: starts the move of a stones

sub pick_up {

	my ( $canvas, $self ) = @_;

	# Don't pick up a stone while loa is still thinking or after the end of
	# the game and don't pick up the opponents stones (unless in edit mode),

	return if &main::get( 'block' );
	return if &main::get( 'over' );
	return if &main::get( 'player' ) ne $self->color
			  and not &main::get( 'edit' );

	# If editing and delete mode is on delete the stone

	return if &main::get( 'edit' ) and
		      &Edit::pick_up( $self->pos, $self->color );

	# Some cosmetics and bindings for Movement and ButtonRelease-1 events

	$canvas->configure( '-cursor' => 'hand2' );
	$canvas->bind( $self->{ ID }, '<Motion>' => [ \&drag, $self ] );
	$canvas->bind( $self->{ ID }, '<ButtonRelease-1>' => [ \&drop, $self ] );

	# Store current position and center stone at the mouse position

	$self->{ cur_x } = $Tk::event->x;
	$self->{ cur_y } = $Tk::event->y;
	$canvas->move( $self->{ ID },
				   $self->{ cur_x } - $self->{ xc },
				   $self->{ cur_y } - $self->{ yc } );
	$canvas->raise( $self->{ ID } );
}


#---------------------
# Callback for Movement events while the left mouse button is pressed, i.e.
# for movements of stones

sub drag {

	my ( $canvas, $self ) = @_;

	$self->move( $canvas, $Tk::event->x, $Tk::event->y );
}

#---------------------
# Does the actual moving and coordinate setting

sub move {

	my ( $self, $canvas, $x, $y ) = @_;

	$canvas->move( $self->{ ID },
				   $x - $self->{ cur_x }, $y - $self->{ cur_y } );
	$self->{ cur_x } = $x;
	$self->{ cur_y } = $y;
}

#---------------------
# Callback for ButtonRelease-1, i.e. when a stone is dropped onto its new
# position

sub drop {

	my $reply;
	my ( $canvas, $self ) = @_;

	&main::set( 'block' => 1 );

	$canvas->configure( '-cursor' => 'top_left_arrow' );

	# Find the stone and check if this was a move in edit mode

	my $to = $opt{ board }->find_field( $Tk::event->x, $Tk::event->y );

	if ( &main::get( 'edit' ) ) {         # in edit mode
		&Edit::move( $self, $self->pos, $to, $self->color );
		&main::set( 'block' => 0 );
		return;
	}

	# Don't do anything except redrawing it if the new position is either
	# invalid (i.e. the stone didn't end up on the board), identical to the
	# old one or loa doesn't like the move...

	unless ( defined $to and $to ne $self->pos and
			 my $ok =
			 ( ( $reply = &main::talk( "move " . $self->pos . " $to" ) )
			   !~ /^\s*error/i ) ) {
		$canvas->bell if defined $ok and not $ok and Menus->get( 'ringbell' );
		$self->draw;
		&main::set( 'block' => 0 );
		return;
	}

	# Remove the opponents stone at the new position (if there's one) and
	# update the move list

	&MList::update( "move: " . $self->pos . "-$to" .
					$opt{ board }->delete_stone( $to ) );

	# Draw the stone at the new position

	$opt{ board }->highlight( $self->pos, $to ); # do highlighting
	$self->pos( $to );                           # set stones s new position
	$self->coord( Board->get_coords( $to ) );    # set its new coordinates
	$self->draw( 1 );                            # redraw it

	# Get loas other comments about the move and show a box on end of game

	while ( $reply !~ /^\s*ok\s*/i ) {
		&show_winner( $reply =~ /\-5000/ ? 'human' : 'loa', 'human' )
			if $reply =~ /5000/;
		$reply = &main::receive( );
	}

	if ( &main::get( 'over' ) ) {
		&main::set( 'block' => 0 );           # remove block at end of game
	} else {
		&play;                                # otherwise let loa make its move
	}
}

#---------------------
# Routine asks loa to make its move - but the real stuff happens in play_on()

sub play {

	&Menus::set( switch_block => 1 );
	$opt{ canvas }->configure( '-cursor' => 'watch' );
	&main::title( ( &main::get( 'player' ) eq 'white' ? "black" : "white" )
				  . "s turn" );
	&MList::update( "calculated: -1 of 100\n" );

	# Instruct xloa to execute play_on() on replies from loa and tell loa
	# to play

    &main::send( "play", 1 );
	&main::set( 'dont_break' => 0 );
}

#---------------------
# This is the routine called when loa has reacted to a play command. Depending
# on its reply either only the progress indicator is updated or loas move is
# shown on the board.

sub play_on {

	&main::set( 'dont_break' => 1 );

	# Get loas reply

	my $reply = &main::receive( );

	# Check reply for errors

	unless ( $reply =~ /(mymove)|(calculated)|(error: maximal)/i ) {
		&main::set( 'dont_break' => 0 );
		&main::suicide;
		die "loa doesn't want to play and says: $reply";
	}

	# Check reply for maximum number of moves

	if ( $reply =~ /error: maximal number of moves reached/ ) {
		&main::set( 'over'  => 7,
					'block' => 0,
					'switch_block' => 0 );
		&main::title( "Draw" );
		$opt{ canvas }->configure( '-cursor' => 'top_left_arrow' );
		$opt{ canvas }->bell if Menus->get( 'alertbell' );
		MBox->show_message( "Maximum nuber of moves reached." );
		&main::set( 'dont_break' => 0 );
        kill 'ALRM', &main::get( 'listener' );    # tell listener to continue
		return;
	}

	# Update the progress indicator

	$reply =~ /calculated: (\d+) of (\d+)/i;
	&MList::update( $reply );

	unless ( $1 == $2 - 1 ) {                     # not final update report ?
		&main::set( 'dont_break' => 0 );
        kill 'ALRM', &main::get( 'listener' );    # tell listener to continue
		return;
	}

	# Get reply with next of loas moves

    kill 'USR2', &main::get( 'listener' );

	$reply = &main::receive( );

	# Remove stone at the new position (if there's one) and update move list

	my ( $keywd, $from, $to ) = split /\s+/, $reply;
	&MList::update( "$keywd $from-$to" . $opt{ board }->delete_stone( $to ) );

	# Draw stone at new position

	my $self = $opt{ board }->find_stone( $from ); # get stone that was moved
	unless ( defined $self ) {
		&main::set( 'dont_break' => 0 );
		&main::suicide;
		die "Internal bug in xloa detected, please send a bug report.\n";
	}

	$self->pos( $to );                             # set its position
	$self->coord( Board->get_coords( $to ) );      # set its coordinates
	$self->draw( 1 );                              # redraw it

	# Some cosmetics: reset the cursor, do highlighting and ring the bell to
	# announce that loa is finished

	$opt{ canvas }->configure( '-cursor' => 'top_left_arrow' );

	$opt{ board }->highlight( $from, $to );
	$opt{ canvas }->bell if Menus->get( 'alertbell' );

	# Read loas other messages and show a box on end of game
    # codes: 1 = loa wins by its last move
    #        2 = human wins by its last move
    #        3 = human wins by loas last move
    #        4 = loa wins by the humans last move
    #        5 = game is over due to creation of a final situation by editing
    #        6 = human wins due loa giving up
	#        7 = game ends because maximum number of moves was reached

	if ( ( $reply = &main::receive( ) ) =~ /5000/ ) {
		&main::receive( );                          # catch 'game over' message
		&show_winner( $reply =~ /\-5000/ ? 'human' : 'loa', 'loa' );
	} elsif ( $reply =~ /offer to give up/i ) {
		if ( &CBox::show_question( ) ) {
			&show_winner( 'human', 'loa' ) ;
			&main::set( 'over' => 6 );
		}
	} else {
		&main::title( &main::get( 'player' ) . "s turn" )
			unless &main::get( 'over' );
	}

	&main::set( 'block' => 0 );
	&Menus::set( 'switch_block' => 0 );
	&main::set( 'dont_break' => 0 );
}

#---------------------
# Shows a box with a message about the winner at end of game

sub show_winner{

	my ( $who, $last_move_by ) = @_;

	if ( $who eq 'human' ) {                                # human wins
		&main::set( 'over' => ( $who eq $last_move_by ? 2 : 3 ) );
		&main::title( "You (" . &main::get( 'player' ) . ") win" );
		MBox->show_message( "Congratulations, you win !" );
	} else {                                                # loa wins
		&main::set( 'over' => ( $who eq $last_move_by ? 1 : 4 ) );
		&main::title( "Loa (" . ( &main::get( 'player' ) eq "black" ?
								  "white" : "black" ) . ") wins" );
		MBox->show_message( "Sorry, but I win :-)" );
	}
}

#---------------------
# Displays all possible moves for a user stone - switch it on by calling the
# routine with the third argument, otherwise switch it off

sub show_moves {

	return if &main::get( 'block' );
	return if &main::get( 'over' );

	my ( $canvas, $self, $state ) = @_;

	unless ( defined $state ) {                 # switch off display
		delete $self->{ 'is_arrows' };
		$canvas->delete( 'move_arrows' );
		return;
	}

	# Ask loa for the possible moves

	my $reply = &main::talk( "from " . $self->pos );
	return if scalar( my @list = split /\s+/, $reply ) < 2; # if there's none

	shift @list;                                # get rid of first word ("to:")
	my @from = ( $self->coord )[ 0..1 ];        # get arrows start point

	foreach ( @list ) {                         # for each possible move
		my @to = ( Board->get_coords( $_ ) )[ 0..1 ];  # get end point
		$canvas->create( 'line',                       # and draw
						 @from, @to,
						 '-arrow' => 'last',
						 '-width' => Board->get( 'fsize' ) / 20 | 1,
						 '-tags' => 'move_arrows',
						 '-fill' => $opt{ movesarrowcolor }
					   );
	}

	$self->{ 'is_arrows' } = 1;
}

#---------------------
# Sets one or more global data of the package

sub set {

	shift;                  # get rid of class or instance
	while ( @_ >= 2 ) {
		my ( $key, $val ) = ( shift, shift );
		$opt{ $key } = $val;
	}
}

#---------------------
# Returns the value of one of the global variables

sub get {

	shift;
	my $key = shift;
	return $opt{ $key };
}

1;
