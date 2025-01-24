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

# Package for editing the board

package Edit;
use strict;
use Tk;
use Board;
use EStone;
use Packer;


my %opt = (

	board      => undef,       # the board object
	canvas     => undef,       # the main canvas
	ecanvas    => undef,       # the edit canvas
	delete     => 0,           # set in delete mode
	stone      => undef,       # stone that's dragged around in the main canvas
	estoneb    => undef,       # black edit stone
	estonew    => undef,       # white edit stone
	del_button => undef,
);


#---------------------
# Toggles edit mode on and off

sub edit {

	if ( &main::get( 'block' ) or &main::get( 'over' ) ) {
		Menus->set( 'edit' => 0 );
		return;
	}

	if ( &main::get( 'edit' ) ) {
		&main::set( 'edit' => 0 );
		&del_toggle if $opt{ delete };
		Menus->set( 'edit' => 0 );
		&destroy;

		# Ask loa if this is a final position and if it is show
		# a message box and keep the game from continuing

		&main::send( "checkpos" );
		my $reply = &main::receive( );
		if ( $reply =~ /final position/ ) {
			&main::set( 'over' => 5 );
			&main::title( "Game over" );
			MBox->show_message( "Game is over!" );
		}
	} else {
		&main::set( 'edit' => 1 );
		Menus->set( 'edit' => 1 );
		$opt{ board }->highlight;
		$opt{ ecanvas } =
			&Packer::make_edit( '-width' => $opt{ canvas }->width,
								'-height' => $opt{ board }->get( 'fsize' ),
								'-borderwidth' => 0 );
	}
}

#---------------------
# (Re)creates the elements in the edit canvas, i.e. the two edit stones and
# the 'Delete' button

sub draw {

	my $ecanvas = shift;

	# Create a button to switch on or off delete mode

	$ecanvas->delete( $opt{ del_button } );
	$opt{ del_button } = $ecanvas->createWindow(
						 $opt{ canvas }->width
						 - $opt{ board }->get( 'border_x' ),
						 $opt{ board }->get( 'fsize' ) / 2,
						 '-anchor' => 'e',
						 '-window' =>
						  $ecanvas->Button( '-text' => "Delete",
											'-command' => \&del_toggle )
					   );

	# Create the edit stones

	make_estone( 'white', $ecanvas );
	make_estone( 'black', $ecanvas );

	&main::get( 'parent' )->bind( '<Control-d>' => \&del_toggle );
	$ecanvas->update;
}

#---------------------
# Creates one of the extra stones used in editing

sub make_estone {

	my ( $color, $ecanvas ) = @_;

	if ( $color eq 'white' ) {
		$opt{ estonew } = $opt{ estonew }->destroy if defined $opt{ estonew };
		$opt{ estonew } = EStone->new( $color, $ecanvas )
			if $opt{ board }->get_stones( $color ) < 12;
	} else {
		$opt{ estoneb } = $opt{ estoneb }->destroy if defined $opt{ estoneb };
		$opt{ estoneb } = EStone->new( $color, $ecanvas )
			if $opt{ board }->get_stones( $color ) < 12;
	}
}

#---------------------
# Deletes the additional elements for editing

sub destroy {

	$opt{ estonew } = $opt{ estonew }->destroy if defined $opt{ estonew };
	$opt{ estoneb } = $opt{ estoneb }->destroy if defined $opt{ estoneb };

	&Packer::destroy_edit;
	$opt{ canvas }->configure( '-cursor' => 'top_left_arrow' );

	&main::get( 'parent' )->bind( '<Control-d>' => "" );
}

#---------------------
# Toggles delete mode on and off

sub del_toggle {

	if ( $opt{ delete } ) {
		$opt{ ecanvas }->configure( '-cursor' => 'top_left_arrow' );
		$opt{ canvas }->configure( '-cursor' => 'top_left_arrow' );
		$opt{ delete } = 0;
	} else {
		$opt{ ecanvas }->configure( '-cursor' => 'pirate' );
		$opt{ canvas }->configure( '-cursor' => 'pirate' );
		$opt{ delete } = 1;
	}
}

#---------------------
# Called from Stone::drop for moving a stone in edit mode, i.e. it lets the
# user pick up a stone on the board and move it to a different position but
# without this being a real move.

sub move {

	my ( $self, $from, $to, $color ) = @_;

	# The stone must land on a field different from the one it started from

	if ( not defined $to or $to eq $from ) {
		$self->draw;
		return;
	}

	# Delete a stone if one is already at the target position

	if ( defined( my $stone = $opt{ board }->find_stone( $to ) ) ) {
		my $del_color = $stone->color;
		$opt{ board }->delete_stone( $to );
		&main::talk( "setstone $to empty" );
		&MList::update( "del $to ($del_color)" );
		Board->set( 'do_get' ) => 1;
		make_estone( $del_color, $opt{ ecanvas } );
		Board->get( 'do_get' ) => 0;
	}

	# Delete the stone at its initial position

	&main::talk( "setstone $from empty" );
	$opt{ board }->delete_stone( $from );

	# Set the new stone

	&main::talk( "setstone $to $color" );
	$opt{ board }->make_stone( $to, $color );
	&MList::update( "move $from-$to ($color)" );
}

#---------------------
# Called from Stone::pickup in edit mode to let the user delete a stone
# in delete mode (instead of moving it as in plain edit mode)

sub pick_up {

	return 0 unless $opt{ delete };

	&main::set( 'block' => 1 );
	my ( $where, $color ) = @_;
	&main::talk( "setstone $where empty" );
	$opt{ board }->delete_stone( $where );
	&MList::update( "del $where ($color)" );
	Board->set( 'do_get' => 1 );
	make_estone( $color, $opt{ ecanvas } );
	Board->set( 'do_get' => 0 );
	&main::set( 'block' => 0 );
	return 1;
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
