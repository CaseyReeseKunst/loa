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

# Package for stone objects used in editing

package EStone;
use strict;
use Tk;
use Stone;
use Board;


my %opt = (
	board         => undef,
	ecanvas       => undef,
	canvas        => undef,
	stonecolor1   => 'black',
	stonecolor2   => 'white',
);


#---------------------

# Creates a new edit stone - must be called with two arguments, its color
# ("white" or "black") and the canvas it belongs to, i.e. the edit canvas.

sub new {
	my $that = shift;
	my $class = ref( $that ) || $that;
	my $self = { };
	bless $self, $class;

	$self->init( @_ );

	return $self;
}

#---------------------
# Creates a stone belonging to the edit canvas and one belonging to the main
# canvas - since both appear at exactly the same position they look like one
# stone

sub init {

	my ( $self, $color, $ecanvas ) = @_;

	# create some easier to read variables

	my $fsize = $opt{ board }->get( 'fsize' );
	my $border_x = $opt{ board }->get( 'border_x' );
	my $radius = $opt{ board }->get( 'radius' );

	$opt{ ecanvas } = $ecanvas;

	# Create a stone to be shown while dragging in the main canvas (eventhough
	# it's created at 'a1' it's moved immediately, so it doesn't show up on
	# the board at all) and remove its bindings (the -2 in the y-position is
	# there to account for the unavoidable gap between the two canvases of
	# 2 points)

	$self->{ stone } = Stone->new( 'a1', $color );
	( $self->{stone }->{ cur_x }, $self->{stone }->{ cur_y } ) =
		( $self->{stone }->{ xc }, $self->{stone }->{ yc } - 2 );

	$opt{ canvas }->bind( $self->{ stone }->{ ID }, $_ => "" )
		foreach ( '<ButtonPress-1>', '<ButtonPress-2>', '<ButtonPress-3>' );

	# Now also create the stone in the edit canvas and move the stone created
	# in the main canvas to its position in the edit canvas (its invisible
	# there)

	if ( $color eq 'white' ) {
		my $x = $self->{ xc } = $border_x + 1.5 * $fsize;
		my $y = $opt{ canvas }->height + 0.5 * $fsize;
		$self->{ yc } = 0.5 * $fsize;
		$self->{ stone }->move( $opt{ canvas }, $x, $y );

		$self->{ ID } = $ecanvas->create( 'oval',
										  $x - $radius,
										  0.5 * $fsize - $radius,
										  $x + $radius,
										  0.5 * $fsize + $radius,
										  '-fill' => $opt{ stonecolor2 },
										  '-outline' => $opt{ stonecolor1 },
										  '-width' => 1 );
	} else {
		my $x = $self->{ xc } = $border_x + 0.5 * $fsize;
		my $y = $opt{ canvas }->height + 0.5 * $fsize;
		$self->{ yc } = 0.5 * $fsize;
		$self->{ stone }->move( $opt{ canvas }, $x, $y );

		$self->{ ID } = $ecanvas->create( 'oval',
										  $x - $radius,
										  0.5 * $fsize - $radius,
										  $x + $radius,
										  0.5 * $fsize + $radius,
										  '-fill' => $opt{ stonecolor1 },
										  '-outline' => $opt{ stonecolor2 },
										  '-width' => 1 );
	}

	$ecanvas->bind( $self->{ ID }, '<ButtonPress-1>' => [ \&pick_up, $self ] );
}

#---------------------
# Deletes an edit stone (i.e. both, the stone in the board and in the edit
# canvas)

sub destroy {

	my $self = shift;
	$self->{ stone }->destroy;
	$opt{ ecanvas }->delete( $self->{ ID } );
	return undef %$self;
}

#---------------------
# Callback for ButtonPress-1 events for an edit stone

sub pick_up {

	my ( $ecanvas, $self ) = @_;

	# Switch of delete mode and set cursors for both canvases

	Edit->set( 'delete' => 0 );
	$ecanvas->configure( '-cursor' => 'hand2' );
	$opt{ canvas }->configure( '-cursor' => 'hand2' );

	# Set new bindings

	$ecanvas->bind( $self->{ ID }, '<Motion>' => [ \&drag, $self ] );
	$ecanvas->bind( $self->{ ID }, '<ButtonRelease-1>' => [ \&drop, $self ] );

	# Move both stones to the mouse position

	my $x = $self->{ cur_x } = $Tk::event->x;
	my $y = $self->{ cur_y } = $Tk::event->y;
	$ecanvas->move( $self->{ ID }, $x - $self->{ xc }, $y - $self->{ yc } );
	$ecanvas->raise( $self->{ ID } );

	$self->{ stone }->move( $opt{ canvas }, $x, $y + $opt{ canvas }->height );
	$opt{ canvas }->raise( $self->{ stone }->{ ID } );

}

#---------------------
# Callback for Motion events for an edit stone

sub drag {

	my ( $ecanvas, $self ) = @_;
	my ( $x, $y ) = ( $Tk::event->x, $Tk::event->y );

	# Move both stones to the new mouse position

	$self->move( $ecanvas, $x, $y );
	$self->{ stone }->move( $opt{ canvas },	$x, $y + $opt{ canvas }->height );
}

#---------------------
# Moves the stone belonging to the edit canvas to a new position

sub move {

	my ( $self, $ecanvas, $x, $y ) = @_;

	$ecanvas->move( $self->{ ID },
					$x - $self->{ cur_x }, $y - $self->{ cur_y } );
	$self->{ cur_x } = $x;
	$self->{ cur_y } = $y;
}

#---------------------
# Callback for ButtonRelease-1 events for an edit stone

sub drop {

	my ( $ecanvas, $self ) = @_;
	my ( $x, $y ) = ( $Tk::event->x, $Tk::event->y );

	# Put edit stones back to their starting position and remove the
	# additional bindings

	$self->move( $ecanvas, $self->{ xc }, $self->{ yc } );
	$ecanvas->bind( $self->{ ID }, $_ => "" )
		foreach ( '<Motion>', '<ButtonRelease-1>' );

	$self->{ stone }->move( $opt{ canvas }, $self->{ xc },
							$self->{ yc } + $opt{ canvas }->height );

	# Reset cursor in both canvases to normal

	$ecanvas->configure( '-cursor' => 'top_left_arrow' );
	$opt{ canvas }->configure( '-cursor' => 'top_left_arrow' );

	# Find out if we ended up on a field in the board

	my $to = $opt{ board }->find_field( $x, $y + $opt{ canvas }->height );
	return unless defined $to;

	# Delete a stone that's already at the target position, but only if its
	# color is different from the edit stone we moved there

	if ( defined( my $del_stone = $opt{ board }->find_stone( $to ) ) ) {
		my $del_color = $del_stone->color;
		return if $del_color eq $self->{ stone }->color;

		$opt{ board }->delete_stone( $to );
		&main::talk( "setstone $to empty" );
		&MList::update( "del $to ($del_color)" );

		&Edit::make_estone( $del_color, $ecanvas );
	}

	# Set the new stone at the target position

	&main::talk( "setstone $to ". $self->{ stone }->color );
	$opt{ board }->make_stone( $to, $self->{ stone }->color );
	&MList::update( "add $to (" . $self->{ stone }->color . ")" );
	&Edit::make_estone( $self->{ stone }->color, $ecanvas );
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
# Returns the value of a global variable

sub get {
	shift;
	my $key = shift;
	return $opt{ $key };
}

1;
