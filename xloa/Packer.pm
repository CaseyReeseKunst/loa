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

# This package is the result of my inability to get the built-in packer to do
# what I want it to do. You have been warned.

package Packer;

use strict;
use Tk;
use Board;
use Edit;


my %opt = (
	win_w          => 0,            # width and height of the main window
	win_h          => 0,

	board          => undef,        # the board object
	board_canvas   => undef,        # theboards canvas
	board_canvas_w => 0,            # width and height of the board canvas
	board_canvas_h => 0,

	edit_canvas    => undef,        # the edit canvas
	edit_canvas_w  => 0,            # width and height of the edit canvas
	edit_canvas_h  => 0,

	menu_h         => 0,            # height of the menu bar

	dont           => 1,            # don't react to Configure events while set
);


#---------------------
# This is a callback routine for Configure events for the MainWindow. Thus we
# get all events of this kind for the MainWindow as well as its siblings. But
# all we're interested in are changes of the size of the MainWindow because we
# need to adjust the sizes of both the board and the edit canvas. The aim of
# all this is, on the one hand, to have the MainWindow enlarged when the edit
# canvas has to be shown and to have its size reduced again when the edit
# canvas is deleted (i.e. when edit mode is left), and, on the other hand, to
# make the height of the edit canvas always as large as one row of the board.

sub configure {

	my $self = shift;

	# We only want to hear about the MainWindow

	return unless $self = &main::get( 'parent' );

	# Make sure we're going to get the newest window sizes

	&main::get( 'parent' )->update;

	# Nothing to be done if the MainWindows size hasn't changed

	return if $opt{ win_w } == &main::get( 'parent' )->width and
			  $opt{ win_h } == &main::get( 'parent' )->height;

	# Save the new sizes

	$opt{ win_w } = &main::get( 'parent' )->width;
	$opt{ win_h } = &main::get( 'parent' )->height;

	# Nothing to be done until after the creation of the board canvas (it's
	# in board_canvas( ) that $opt{ done } is reset)

	return if $opt{ dont };

	$opt{ menu_h } = Menus->get( 'menubar' )->height;

	# Resize both canvases according to the new window sizes

	&resize;
}

#---------------------
# Calculates the sizes of both the canvases and configures them accordingly

sub resize {

	$opt{ dont } = 1;            # no window updates in the mean time

	# Lets have some simpler variables

	my ( $ww, $wh ) = ( $opt{ win_w }, $opt{ win_h } - $opt{ menu_h } );
	my $bs_ratio = $opt{ board }->get( 'bs_ratio' );
	my $is_edit = &main::get( 'edit' );

	# Start to calculate the sizes starting from the new window width

	my $size = $ww / ( 1 + 2 * $bs_ratio );
	my $fsize = $size /  8;
	my $border_x = my $border_y = ( $ww - $size ) / 2;

	my $total_height = 2 * $border_y + $size + ( $is_edit ? $fsize : 0 );

	# If the resulting height is larger than the window height (of course,
	# after subtracting the menu height) we've got to recalculate everything
	# starting with the new window height

	if ( $total_height > $wh )
	{
		$size = $wh / ( ( $is_edit ? 9 / 8 : 1 ) + 2 * $bs_ratio );
		$fsize = $size / 8;
		$border_y = ( $wh - $size - ( $is_edit ? $fsize : 0 ) ) / 2;
		$border_x = ( $ww - $size ) / 2;
	} else {
		$border_y = ( $wh - $size - ( $is_edit ? $fsize : 0 ) ) / 2;
	}

	# Calculate the remaining sizes the Board package needs and tell it
	# about them

	my $border = $border_x < $border_y ? $border_x : $border_y;

	my $radius = 0.45 * $fsize;
	$radius = $fsize / 2 - 1 if $radius >= $fsize / 2;

	$opt{ board}->set( 'size' => $size, 'border' => $border,
					   'border_x' => $border_x, 'border_y' => $border_y,
					   'fsize' => $fsize, 'radius' => $radius );

	# Resize the board canvas and redraw it

	$opt{ board_canvas_w } = $ww;
	$opt{ board_canvas_h } = $wh - ( $is_edit ? $fsize : 0 );

	# Why, for the heck of it, do we always get a canvas two points larger in
	# both dimensions than we asked for?

	$opt{ board_canvas }->configure( '-width' => $opt{ board_canvas_w } - 2,
									 '-height' => $opt{ board_canvas_h } - 2 );
	$opt{ board_canvas }->update;
	$opt{ board }->draw;

	# Also resize the edit canvas (if it's shown)

	if ( $is_edit ) {

		$opt{ edit_canvas_w } = $ww;
		$opt{ edit_canvas_h } = $fsize;

		$opt{ edit_canvas }->configure(
									  '-width'  => $opt{ edit_canvas_w } - 2,
									  '-height' => $opt{ edit_canvas_h } - 2 );
		$opt{ edit_canvas }->update;
		&Edit::draw( $opt{ edit_canvas } );
	}

	$opt{ dont } = 0;
}

#---------------------
# creates the board canvas

sub make_board {

	my %h = @_;

	# Make sure we get really the sizes we ask for - so we subtract the
	# two points that always get added to the canvas sizes... (since the
	# keyword for the width and height are valid with and without a minus
	# we make sure we get them right in both cases)

	$h{ -width } -= 2 if defined $h{ -width };
	if ( defined $h{ width } ) {
		$h{ -width } = $h{ width } - 2;
		delete $h{ width };
	}
	$h{ -height } -= 2 if defined $h{ -height };
	if ( defined $h{ height } ) {
		$h{ -height } = $h{ height } - 2;
		delete $h{ height };
	}

	my $canvas = &main::get( 'parent' )->Canvas( %h
											   )->pack( '-side' => 'top',
														'-anchor' => 'nw',
														'-fill' => 'none',
														'-expand' => 0 );
	$opt{ board } = Board->get( 'self' );
	$opt{ board_canvas } = $canvas;
	$canvas->update;
	$opt{ board_canvas_w } = $canvas->width;
	$opt{ board_canvas_h } = $canvas->height;

	$opt{ dont } = 0;
	return $canvas;
}

#---------------------
# Creates the edit canvas and increases the window size so that it's always
# shown (would have been nice if the built-in packer could be convinced that
# this can be a good thing)

sub make_edit {

	$opt{ dont } = 1;

	my %h = @_;

	# Again, we have to fight the packers idea about the correct canvas size...

	$h{ -width } -= 2 if defined $h{ -width };
	if ( defined $h{ width } ) {
		$h{ -width } = $h{ width } - 2;
		delete $h{ width };
	}
	$h{ -height } -= 2 if defined $h{ -height };
	if ( defined $h{ height } ) {
		$h{ -height } = $h{ height } - 2;
		delete $h{ height };
	}

	# Resize the window to fit our needs

	my $wx = &main::get( 'parent' )->rootx;
	my $wy = &main::get( 'parent' )->rooty;

	&main::get( 'parent' )->geometry( $opt{ win_w } . "x" .
									  int( $opt{ win_h } + $h{ -height } + 2 )
									  . "+$wx+$wy" );

	# Create the edit canvas in the new free space

	my $canvas = &main::get( 'parent' )->Canvas( %h
											   )->pack( '-side' => 'top',
														'-anchor' => 'nw',
														'-fill' => 'none',
														'-expand' => 0 );
	$opt{ edit_canvas } = $canvas;
	$canvas->update;
	$opt{ edit_canvas_w } = $canvas->width;
	$opt{ edit_canvas_h } = $canvas->height;
	&Edit::draw( $opt{ edit_canvas } );

	$opt{ dont } = 0;

	return $canvas;
}

#---------------------
# Deletes the edit canvas and resizes the window to get rid of the now empty
# area it used to occupy

sub destroy_edit {

	$opt{ dont } = 1;

	$opt{ edit_canvas }->destroy;

	my $wx = &main::get( 'parent' )->rootx;
	my $wy = &main::get( 'parent' )->rooty;

	&main::get( 'parent' )->geometry( $opt{ win_w } . "x" .
									  int( $opt{ win_h }
										   - $opt{ edit_canvas_h } ) .
									  "+$wx+$wy" );

	$opt{ dont } = 0;
}

1;
