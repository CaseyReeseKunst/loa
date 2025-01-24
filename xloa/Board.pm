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

# Package that takes care of drawing and maintaining the board

package Board;
use strict;
use Tk;
use Stone;
use Packer;

# Global data to be used by all board objects, set them with
# Board->set( key => value );
# The values given are here are not relevant and are replaced by the
# initialistation routines, so apply changes to %defaults in Init.pm!

my %opt = (
	self           => undef,
	size           => 400,
	border         => 20,
	border_x       => 20,
	border_y       => 20,
	bs_ratio       => 0.05,
	fsize          => 50,
	radius         => 22.5,
	background     => 'black',
	boardcolor1    => 'pale green',
	boardcolor2    => 'papaya whip',
	hintarrowcolor => 'red',
	fontcolor      => 'WhiteSmoke',
	highlight      => 0,
	highlighcolor  => 'yellow',
	boardfont      => '-*-helvetica-bold-r-*--*-120-*',
	do_get         => 0,                 # only used in get_stones
);

# Each board object has the following properties set
#
#	canvas     the canvas
#	board      ID of board
#	fields     (reference to) hash with field IDs => position entries
#	stones     (reference to) array of stone objects
#   white      (reference to) array with white stones positions
#   black      (reference to) array with black stones positions
#   hl         (reference to) array with positions of highlighted fields
#   is_arrow   exists while hint arrow is shown

#---------------------
# Creates a new game board object

sub new {

	bless my $self = { }, shift;
	$self->init( @_ );
	return $self;
}

#---------------------
# Sets up the new game board

sub init {

	$opt{ self } = my $self = shift;             # so I know who I am ;-)

	$self->{ $_ } = [ ] foreach qw/ stones white black hl /;
	$self->{ draw_block } = 0;

	$opt{ fsize } = $opt{ size } / 8;
	$opt{ radius } = 0.45 * $opt{ fsize };

	# Create the canvas and set bindings

	my $canvas = $self->{ canvas } =
		&Packer::make_board( '-width' =>  $opt{ size } + 2 * $opt{ border_x },
							 '-height' => $opt{ size } + 2 * $opt{ border_y },
							 '-background' => $opt{ background },
							 '-borderwidth' => 0 );

	$canvas->CanvasBind( '<ButtonPress-2>'   => [ \&show_hint, $self, 1 ] );
	$canvas->CanvasBind( '<ButtonRelease-2>' => [ \&show_hint, $self ] );

	# Tell the diverse packages about the board and the canvas

	$_->set( 'board' => $self, 'canvas' => $canvas )
		foreach qw/ Stone Menus Save Edit EStone /;

	# Finally draw the board (redraws are handled by the Packer package)

	$self->draw;
}

#---------------------
# Destroys the game board

sub destroy {

	my $self = shift;

	$self->{ canvas }->destroy;
	return undef %$self;
}

#---------------------
# Draws (or redraws) the complete game board with all its elements

sub draw {

	my $self = shift;

	# avoid multiple redraws at the same time, may otherwise lead to a
	# segmentation fault...

	return if $self->{ draw_block };
	$self->{ draw_block } = 1;

	# (Re)create the elements of the board

	$self->draw_fields;
	$self->draw_letters;
	$self->draw_stones;
	$self->highlight( @{ $self->{ hl } } );

	$self->{ draw_block } = 0;
}

#---------------------
# Draws (or redraws) all the fields of the game board

sub draw_fields {

	my $self = shift;
	my $canvas = $self->{ canvas };

	# Delete the old fields (if there are any) and create new ones

	$canvas->delete( 'fields' );
	$self->{ fields } = { };

	foreach my $i ( 1..8 ) {
		( my $k = $i ) =~ tr/1-8/a-h/;
		foreach ( 1..8 ) {
			my $ID = $canvas->create( 'rectangle',
									  $opt{ border_x }
									  + ( $i - 1 ) * $opt{ fsize },
									  $opt{ size } + $opt{ border_y }
									  - ( $_ - 1 ) * $opt{ fsize },
									  $opt{ border_x } + $i * $opt{ fsize },
									  $opt{ size } + $opt{ border_y }
									  - $_ * $opt{ fsize },
									  '-tags' => 'fields',
									  '-fill' => ( $i + $_ ) & 1 ?
									  $opt{ boardcolor1 } :
									  $opt{ boardcolor2 } );
			${ $self->{ fields } }{ $ID } = "$k$_";
		}
	}
}

#---------------------
# Takes care of drawing the letters around the board

sub draw_letters {

	my $self = shift;

	# Delete old letters (if there are any) and draw new ones

	$self->{ canvas }->delete( 'letters' );
	$self->draw_letter( $_ ) foreach ( 1..8, 'a' .. 'h' );
}

#---------------------
# Draws one pair of letters on opposite sides of the board

sub draw_letter {

	my ( $self, $letter ) = @_;
	my ( @w1, @w2 );

	# Calculate the positions of the letters to be drawn...

	if ( $letter =~ /[1-8]/ ) {
		@w1 = ( $opt{ border_x } - $opt{ border } / 2,
				$opt{ size } + $opt{ border_y }
				- ( $letter - 0.5 ) * $opt{ fsize } );
		@w2 = ( $opt{ size } + $opt{ border_x }	+ $opt{ border } / 2,
				$opt{ size } + $opt{ border_y }
				- ( $letter - 0.5 ) * $opt{ fsize } );
	} else {
		( my $k = $letter ) =~ tr/a-h/1-8/;
		@w1 = ( $opt{ border_x } + ( $k - 0.5 ) * $opt{ fsize },
				$opt{ border_y } - $opt{ border } / 2 );
		@w2 = ( $opt{ border_x } + ( $k - 0.5 ) * $opt{ fsize },
				$opt{ size } + $opt{ border_y }	+ $opt{ border } / 2 );
	}

	# ...and draw them

	$self->{ canvas }->create( 'text',
							   @w1,
							   '-tags' => 'letters',
							   '-text' => $letter,
							   '-justify' => 'center',
							   '-fill' => $opt{ fontcolor },
							   '-font' => $opt{ boardfont } );
	$self->{ canvas }->create( 'text',
							   @w2,
							   '-tags' => 'letters',
							   '-text' => $letter,
							   '-justify' => 'center',
							   '-fill' => $opt{ fontcolor },
							   '-font' => $opt{ boardfont } );
}

#---------------------
# Creates and draws all stones on the board according to the information
# received from loa

sub draw_stones {

	my $self = shift;

	# delete old stones

	$self->store_stone_pos;
	$_->destroy foreach ( @{ $self->{ stones } } );
	$self->{ stones } = [ ];

	# Ask loa for the positions of the new stone and create them

	foreach my $color ( "white", "black" ) {
		$self->make_stone( $_, $color )
			foreach ( $self->get_stones( $color ) );
	}
}

#---------------------

sub make_stone {
	my ( $self, $pos, $color ) = @_;
	push @{ $self->{ stones } }, Stone->new( $pos, $color );
}

#---------------------
# Calculates the coordinates of a stone at a location passed to the routine in
# the format /^[a-h][1-8]$/i. It not only returns the center x- and y-position
# but also the positions of the upper left and the lower right corner as needed
# for drawing the stone as an oval in the canvas.

sub get_coords {

	shift;
	my $pos = shift;

	$pos =~ /^([a-h])([1-8])$/i or die "Invalid position: '$pos'\n";
	( my $x = $1 ) =~ tr/a-z/0-7/;

	$x = $opt{ border_x } + ( $x + 0.5 ) * $opt{ fsize };
	my $y = $opt{ size } + $opt{ border_y }
	        - ( $2 - 0.5 ) * $opt{ fsize };

	return int( $x ), int( $y ),                                   # center
		   int( $x - $opt{ radius } ), int( $y - $opt{ radius } ), # ul
		   int( $x + $opt{ radius } ), int( $y + $opt{ radius } ); # lr
}

#---------------------
# Finds the field located at the coordinates passed to the routine - returns
# the field in the format /^[a-h][1-8]$/ or undef if no field is at these
# coordinates

sub find_field {

	my ( $self, $x, $y ) = @_;

	# Get a list of IDs of all items at the coordinates

	my @list = $self->{ canvas }->find( 'overlapping', $x, $y, $x, $y );
	return undef if @list < 1;

	# Find the first element in the list that is a key in the fields hash and
	# return the associated value, i.e. the position

	foreach ( @list ) {
		return ${ $self->{ fields } }{ $_ }
			if exists ${ $self->{ fields } }{ $_ };
	}

    undef;
}

#---------------------
# Deletes the stone object and its entry in the boards list of stones at a
# position (in format /^[a-h][1-8]$/i) received as the argument. It returns a
# space character if no stone was found at the position, otherwise a '+'

sub delete_stone {

	my ( $self, $pos )  = @_;

	$pos =~ /^[a-h][1-8]$/i or die "Invalid position: '$pos'";

	my ( $stone, $index ) = $self->find_stone( $pos );
	return " " unless defined $stone;

	$stone->destroy;
	splice @{ $self->{ stones } }, $index, 1;
	return "+";
}

#---------------------
# Runs through the boards list of stone objects to find the one at the position
# received as the argument (in format /^[a-h][1-8]$/i) and returns the stone
# reference (if called in scalar context) as well as the the position in the
# boards stone list (if called in a list context)

sub find_stone {

	my ( $self, $pos )  = @_;

	my $i = 0;
	foreach ( @{ $self->{ stones } } ) {
	    return wantarray ? ( $_, $i ) : $_ if $_->pos eq $pos;
		$i++;
	}

    return wantarray ? ( ) : undef;
}

#---------------------
# Does the highlighting of the fields a stone was moved from and to

sub highlight {

	my ( $self, $from, $to ) = @_;
	my $canvas = $self->{ canvas };

	# Undo highlighting of previously highlighted fields

	$canvas->delete( 'hl' );
	$self->{ hl } = [ ];

	return unless $opt{ highlight } and defined $from and defined $to;

	# Calculate position of 'from'-field and highlight it

	$self->{ hl } = [ $from, $to ];

	$from =~ /^([a-h])([1-8])$/i or die "Invalid 'from' position: '$from'";
	( my $x = $1 ) =~ tr/a-z/0-7/;

	$x = $opt{ border_x } + $x * $opt{ fsize };
	my $y = $opt{ size } + $opt{ border_y } - $2 * $opt{ fsize };

	$canvas->create( 'line',
					 $x, $y,  $x + $opt{ fsize }, $y,
					 $x + $opt{ fsize }, $y + $opt{ fsize },
					 $x, $y + $opt{ fsize },
					 $x, $y,
					 '-tags' => 'hl',
					 '-fill' => $opt{ highlightcolor },
					 '-width' => 2
				   );

	# Calculate position of 'to'-field and highlight it

	$to =~ /^([a-h])([1-8])$/i or die "Invalid 'to' position: '$to'";
	( $x = $1 ) =~ tr/a-z/0-7/;

	$x = $opt{ border_x } + $x * $opt{ fsize };
	$y = $opt{ size } + $opt{ border_y } - $2 * $opt{ fsize };

	$canvas->create( 'line',
					 $x, $y,  $x +$opt{ fsize }, $y,
					 $x+ $opt{ fsize }, $y + $opt{ fsize },
					 $x, $y + $opt{ fsize },
					 $x, $y,
					 '-tags' => 'hl',
					 '-fill' => $opt{ highlightcolor },
					 '-width' => 2
				   );
}

#---------------------
# Toggles use of highlighting of last move on or off

sub toggle_highlight {

	if ( $opt{ highlight } ) {                    # switch off highlighting
		$opt{ highlight } = 0;
		$opt{ self }->highlight;
		Menus->set( 'highlight' => 0 );
	}
	else                                          # switch on highlighting
	{
		$opt{ highlight } = 1;
		Menus->set( 'highlight' => 1 );
		if ( &MList::length != 0 ) {
			&MList::thelast =~ /([a-z][1-8])\-([a-z][1-8])/i;
			$opt{ self }->highlight( $1, $2 );
		}
	}
}

#---------------------
# Shows loa's idea about the best next move for the user

sub show_hint {

	my ( $canvas, $self, $state ) = @_;

	unless ( defined $state ) {                   # switch off hint arrow
		delete $self->{ is_arrow };
		$canvas->delete( 'hint_arrow' );
		return;
	}

	return if &main::get( 'block' );
	return if &main::get( 'over' );

	my $reply = &main::talk( "hint" );

	return if $reply =~ /^error/;

	$reply =~ tr/A-H/a-h/;
	return if scalar( my ( $from, $to ) = split /\s+\-\s+/, $reply ) < 2;

	$canvas->create( 'line',
					 ( $self->get_coords( $from ) )[ 0..1 ],
					 ( $self->get_coords( $to ) )[ 0..1 ],
					 '-arrow' => 'last',
					 'width' => $opt{ fsize } / 20 | 1,
					 '-tags' => 'hint_arrow',
					 '-fill' => $opt{ hintarrowcolor }
				   );
}

#---------------------
# Returns the ID of a field at a given position (in format /^[a-h][1-8]$/i)

sub get_field_ID {

	my ( $self, $pos ) = @_;
	return ${ { reverse %{ $self->{ fields } } } }{ $pos };
}

#---------------------
# Updates the internal list of stone positions. Should be called after every
# 'showwhite' and 'showblack' command and before all stones are deleted.

sub store_stone_pos {

	my ( $self, $color ) = ( shift, shift );

	if ( defined $color ) {

		$self->{ $color } = [ ];
		push @{ $self->{ $color } }, @_;

	} else {

		$self->{ white } = [ ];
		$self->{ black } = [ ];

		push @{ $self->{ $_->color } }, $_->pos
			foreach ( @{ $self->{ stones } } );
	}
}

#---------------------
# If called in scalar context returns the number of stones with the color
# passed as argument ('black' or 'white'), in array context a list of all
# the stone positions. If loa is busy it's not asked but the internal
# list of the stone positions is returned.

sub get_stones {

	my ( $self, $color ) = @_;
	my @list = ( );

	if ( $opt{ do_get } or not &main::get( 'block' ) ) {    # get list from loa

		@list = split /\s+/, &main::talk( "show" . $color );
		$self->store_stone_pos( $color, @list );     # update the internal list

	} else {                                # don't bother loa, use stored data
		push @list, @{ $self->{ $color } };
	}

	return @list;
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
# Returns the value of one of the gloabal variables

sub get {
	shift;
	my $key = shift;
	return $opt{ $key };
}

1;
