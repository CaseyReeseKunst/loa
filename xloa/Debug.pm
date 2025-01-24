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

# As the name says this package is for debugging purposes only so it
# shouldn't be interesting for most people...
# To get at the debugging menu press <Alt><Ctrl><Shift>d and use with care.

package Debug;
use strict;
use Menus;
use Board;


sub show {

	my $i;
	my $debug = &main::get( 'debug_level' );
	&main::set( 'debug_level' => 0 );

	print STDERR "LOA's map\n";
	&main::send( "show" );
	for $i ( 0..8 ) {
		print STDERR &main::receive( );
	}
	&main::set( 'debug_level' => $debug );
}

sub talk_to_loa {

	my ( $lb, $send );
	my $talk = &main::get( 'parent' )->Toplevel;

	$talk->Entry( '-width' => 20,
				  '-textvariable' => \$send,
				  '-font' => Menus->get( 'menufont' )
			    )->pack( '-padx' => '1m',
						 '-pady' => '1m' );
	$talk->Button( '-text' => "Send",
				   '-font' => Menus->get( 'menufont' ),
				   '-command' => [ \&talk_send, \$send, \$lb ]
				   )->pack( '-padx' => '1m',
							'-pady' => '1m' );
	$lb = $talk->Scrolled( 'Listbox',
						   '-scrollbars' => 'osoe',
						   '-font' => Menus->get( 'menufont' ),
						 )->pack( '-fill' => 'both',
									 '-expand' => 1 );
	$talk->Button( '-text' => "Get reply",
				   '-font' => Menus->get( 'menufont' ),
				   '-command' => [ \&talk_get_reply, \$lb ]
				   )->pack( '-padx' => '1m',
							'-pady' => '1m' );
	$talk->Button( '-text' => 'Close',
				   '-font' => Menus->get( 'menufont' ),
				   '-command' => sub { $talk->destroy }
				 )->pack( '-pady' => '2m' );
}


sub talk_send {

	my $send = shift;
	return unless defined $$send;    # don't send empty string...
	&main::send( "$$send" );
	&talk_get_reply( shift );        # assumes loa always replays with one line
	Board->get( 'self' )->draw;
}

sub talk_get_reply {

	my $lb = shift;
	my $reply = &main::receive( );
	chomp $reply;
	$$lb->insert( 'end', "$reply" );
	$$lb->see( 'end' );
}

1;
