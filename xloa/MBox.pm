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

# Creates a window with a short message

package MBox;
use strict;
use Tk;
use Menus;


my %opt = (
	menufont => '-*-helvetica-bold-r-*--*-120-*',
);


#---------------------
# Shows a message with the text received as argument at the center of the
# board - while the box is shown all other actions are blocked

sub show_message {

	&main::set( 'mess_block' => 1 );

	shift;
	my ( $text, $title ) = @_;
	my $mess_end = 0;

	my $mw = &main::get( 'parent' );

	my $box = $mw->Toplevel( '-title' => defined $title ?
										 "Xloa: Error" : "Xloa: Game over" );

	my $frame1 = $box->Frame( '-relief' => 'raised',
							  'borderwidth' => '1'
							)->pack( '-fill' => 'both',
									 '-expand' => 1 );

	$frame1->Label( '-text' => $text,
					'-font' => $opt{ menufont }
				  )->pack ( '-pady' => '4m',
							'-padx' => '4m' );

	my $frame2 = $box->Frame( '-relief' => 'raised',
							  '-borderwidth' => '1'
							)->pack( '-fill' => 'x' );

	$frame2->Button( '-text' => "Ok",
					 '-font' => $opt{ menufont },
					 '-command' => sub { $mess_end = 1 }
				   )->pack( '-padx' => '2m',
							'-pady' => '2m' );

	$mw->bind( 'all', '<Return>', sub { $mess_end = 1 } );
	$mw->bind( 'all', '<KP_Enter>', sub { $mess_end = 1 } );

	# Try to position the message box in the center of the main window

	$box->waitVisibility;      # otherwise the next 2 lines don't make sense...
	$box->update;
	my $x = int( $mw->rootx + ( $mw->width - $frame1->width ) / 2 );
	my $y = int( $mw->rooty
				 + ( $mw->width -$frame1->height + $frame2->height ) / 2 );
    $box->geometry( "+$x+$y" );

	# Wait for the OK button to be pressed

	$box->focus;
    $box->waitVariable( \$mess_end );
	$mw->bind( 'all', '<Return>', "" );
	$mw->bind( 'all', '<KP_Enter>', "" );
	$mw->focus;
	$box->destroy;

	&main::set( 'mess_block' => 0 );
}

#---------------------
# Sets one or more of the global variables of the package

sub set {

	shift;
	while ( @_ >= 2 ) {
		my ( $key, $val ) = ( shift, shift );
		$opt{ $key } = $val;
	}
}

1;
