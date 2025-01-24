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

# Packages for maintaining the move list and displaying it

package MList;
use strict;
use Tk;


my %opt = (
	self              => undef,
	movelist          => [ ],
	list              => undef,
	scale             => undef,
	progress          => 0,
	menufont          => undef,
);


#---------------------
# Creates the move list

sub make {

	# Create a window for the move list und unmap it (unless the menu says
	# otherwise)

	my $ml = $opt{ self } =
		&main::get( 'parent' )->Toplevel( '-title' => 'Xloa: Move List' );
	$ml->withdraw unless Menus->get( 'is_movelist' );
	$ml->bind( '<Destroy>' => \&recreate );

	# Create the move list

    $opt{ list } = $ml->Scrolled( 'Listbox',
								  'selectmode' => 'extended',
								  '-scrollbars' => 'osoe',
								  'font' => $opt{ menufont },
								 )->pack( 'side' => 'top',
										  'fill' => 'both',
										  'anchor' => 's',
										  'expand' => 1 );

	$opt{ scale } = $ml->Scale( '-orient' => 'horizontal',
								 '-from' => 0,
								 '-to' => 100,
								 '-label' => 'Progress indicator:',
								 '-showvalue' => 1,
								 '-resolution' => 1,
								 '-tickinterval' => 25,
								 '-font' => $opt{ menufont }
							   )->pack( 'fill' => 'x' );
	
	$opt{ scale }->set( $opt{ progress } );
	$opt{ scale }->configure( '-command' =>
							  sub {	$opt{ scale }->set( $opt{ progress } ) } );

	# Create a `Close'-button

	$ml->Button( '-text' => 'Close',
				 '-font' => $opt{ menufont },
				 '-command' => \&show
				)->pack( 'pady' => '2m',
						 'anchor' => 's' );
}

#---------------------
# To avoid that the user completely destroys the move list by creating a
# Destroy event, the list is immediately recreated and repopulated on such an
# event - but it remains invisible, so that a Destroy event has the same
# result (at the least as far as the user sees it) as clicking onto the
# 'Close' button

sub recreate {

	my $who = shift;
	return unless $who eq $opt{ self };  # only for the top window

	# Make sure the move list remains invisible when it's recreated

	Menus->set( 'is_movelist' => 0 );

	# Recreate the box and rewrite all entries

	&make;
	foreach ( splice @{ $opt{ movelist } }, 0 ) {
		if ( /^[a-h][1-8]-[a-h][1-8]/i ) {
			&update( "move: " . $_ );
		} else {
			&update( $_ );
		}
	}
}

#---------------------
# Toggles between mapped and unmapped state of the move list window

sub show {

	if ( $opt{ self }->state eq 'withdrawn' ){
		$opt{ self }->deiconify;
		Menus->set( 'is_movelist' => 1 );
	} else {
		$opt{ self }->withdraw;
		Menus->set( 'is_movelist' => 0);
	}
}

#---------------------
# Updates the moves list - expects a string starting with:
# "clear":      clear (only to be used at the start of the program)
# "move:"       add the move (note the colon !)
# "mymove:"     add the move
# "calculated:" update progress meter
# "delete"      delete last stored move
# "move"        move in edit mode (without a colon !)
# "add"         add a stone (edit mode)
# "del"         delete a stone (edit mode)

sub update {

	my $cmd = shift;

	if ( $cmd =~ /clear/ ) {                             # at start of new game
		$opt{ movelist } = [ ];
		$opt{ progress } = 0;
		$opt{ list }->delete( 0, 'end' );
		$opt{ scale }->set( $opt{ progress } );
	}

	if ( $cmd =~ /calculated: (-?\d+) of (\d+)/i ) {
		$opt{ scale }->set( $opt{ progress } = ( $1 + 1 ) / $2 * 100 );
	}

	if ( $cmd =~ /(my)?move:\s*(.*)/ ) {                 # append a new move
		my $themove = $2;
		$opt{ progress } = 100;
		$opt{ scale }->set( $opt{ progress } );
		if ( &num_moves & 1 ) {
			if ( &last_is_edit ) {
				$opt{ list }->insert( 'end', ( &num_moves >> 1 ) + 1 . ": " .
									  "      " . " : " . $themove );
			} else {
				$opt{ list }->delete( 'end' );
				$opt{ list }->insert( 'end', ( &num_moves >> 1 ) + 1 . ": " .
									  &thelast . " : " . $themove );
			}
		} else {
			$opt{ list }->insert( 'end',
								  ( &num_moves >> 1 ) + 1 . ": " . $themove );
		}
		$opt{ list }->see( 'end' );
		push @{ $opt{ movelist } }, $themove;
	}

	if ( $cmd =~ /delete/ ) {                            # delete last move
		return if &length == 0;
		my $was_edit = &last_is_edit;
		pop @{ $opt{ movelist } };
		$opt{ list }->delete( 'end' );
		return if &length == 0;
		$opt{ list }->insert( 'end',
							  ( &num_moves >> 1 ) + 1 . ": " . &thelast )
			if &num_moves & 1 and not ( $was_edit or &last_is_edit );
		$opt{ list }->see( 'end' );
		$opt{ self }->update;
		if ( &last_is_edit and not $was_edit ) {
			&undo_undo_edit;
		}
	}

	if ( $cmd =~ /^\s*(add)|(del\s+)|(move[^\:])/i ) {   # append an edit move
		push @{ $opt{ movelist } }, $cmd;
		$opt{ list }->insert( 'end', $cmd );
		$opt{ list }->see( 'end' );
		$opt{ self }->update;
	}
}

#---------------------
# Returns the number of moves (including moves in edit mode) in the move list

sub length {
	return scalar @{ $opt{ movelist } };
}

#---------------------
# Returns the number of real moves (i.e. excluding moves in edit mode) in
# the move list

sub num_moves {

	my $count = 0;
	foreach ( @{ $opt{ movelist } } ) {
		$count += 1 unless /^(add)|(del)|(move)/i;
	}
	return $count;
}

#---------------------
# Returns the last entry in the move list

sub thelast {
	return ${ $opt{ movelist } }[ -1 ];
}

#---------------------
# Returns true if the last move in the move list has been done in edit mode

sub last_is_edit {
	return &thelast =~ /^(add)|(del)|(move)/i;
}

#---------------------
# Redoes the edit moves that have been undone by loa on a takeback command

sub undo_undo_edit {

	my $add  = '^\s*add\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $del  = '^\s*del\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $move = '^\s*move\s+([a-h][1-8])\-([a-h][1-8])\s+\(((white)|(black))\)';

	# Find index of last undone edit move in the move list

	my $first = &length;
	foreach ( reverse @{ $opt{ movelist } } ) {
		last unless /^\s*(add)|(del)|(move)/i;
		$first--;
	}

	# Redo all undone edit moves at the end of the list

	foreach ( @{ $opt{ movelist } }[ $first..( &length - 1 ) ] ) {
		if ( /$add/i ) {
			&main::talk( "setstone $1 $2" );
		} elsif ( /$del/i ) {
			&main::talk( "setstone $1 empty" );
		} else {
			/$move/i;
			&main::talk( "setstone $1 empty" );
			&main::talk( "setstone $2 $3" );
		}
	}
}

#---------------------
# Sets one or more global data of the package

sub set {
	shift;
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
