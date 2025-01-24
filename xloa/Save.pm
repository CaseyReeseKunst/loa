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

# Package for storing and loading games

package Save;
use FileHandle;
use Tk;
require Tk::FileSelect;
use Board;
use Stone;
use MList;


my %opt = (
	canvas    => undef,
	board     => undef,
	extension => 'loa'
);


#---------------------
# Stores a game in a file

sub save {

	my $F = new FileHandle;
	my $file;

	# Don't do anything if move list is empty

	return if &MList::length == 0;

	# Get a file name and try to open it

	my $fs = &main::get( 'parent' )->FileSelect( '-directory' => "./",
												 '-filter' => "*" .
											   ( $opt{ extension } eq "" ? "" :
											   ( ".". $opt{ extension } ) ) );

	return unless defined( $file = $fs->Show );

	unless ( $F->open( ">$file" ) ) {
		MBox->show_message( "Can't open file $file for writing.", 1 );
		return;
	}

	# Write all relevant information about the game into the file

	print $F "# File has been written by xloa - do not edit\n";
	print $F ( &main::get( 'scrambled' ) ? "Scrambled\n" : "Normal\n" );
	for ( my $i = 0; $i < &MList::length; $i++ ) {
		print $F ${ MList->get( 'movelist' ) }[ $i ] . "\n";
	}

    # Codes: 1 = loa wins by its last move
    #        2 = human wins by its last move
    #        3 = human wins by loas last move
    #        4 = loa wins by the humans last move
    #        5 = game is over due to creation of a final situation by editing
    #        6 = human wins due loa giving up
    #        7 = game got stopped after maximum number of moves

	if ( &main::get( 'over' ) ) {
		if ( &main::get( 'over' ) == 5 ) {
			print $F "Game over (5";
		} elsif ( &main::get( 'over' ) == 2 or &main::get( 'over' ) == 3 ) {
			print $F "Human wins (" . &main::get( 'over' );
		} elsif ( &main::get( 'over' ) == 1 or &main::get( 'over' ) == 4 ) {
			print $F "LOA wins (" . &main::get( 'over' );
		} elsif ( &main::get( 'over' ) == 6 ) {
			print $F "LOA gives up (6";
		} else {
			print $F "Maximum number of moves reached (7";
		}
	} else {
		printf $F "(";
	}

    printf $F ( &main::get( 'player' ) eq "black" ? "b" : "w" ) . ")\n";
	$F->close;
};

#---------------------
# Loads a game from a file (a file name can be given as argument)

sub load {

	my $F = new FileHandle;
	my $reply;
	my $file = shift;

	my $p1 = '^\s*([a-h][1-8])\-([a-h][1-8])(\+)?';
	my $p2 = '^\s*move\s+([a-h][1-8])\-([a-h][1-8])\s+\(((white)|(black))\)';
	my $p3 = '^\s*add\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $p4 = '^\s*del\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $p5 = '^\s*LOA gives up\s*\(\s*6\s*[bw]\s*\)';
	my $p6 = '^\s*Game over\s*\(\s*5\s*[bw]\s*\)';
	my $p7 = '^\s*\(\s*([bw])\s*\)';

	# Don't load while in edit mode

	if ( &main::get( 'edit' ) ) {
		MBox->show_message( "Can't load file $file while editing.", 1 );
		return;
	}

	&main::set( 'block' => 1 );

	# If no file is given as argument get a file name and open it for reading

	if ( not defined $file )
	{
		my $fs = &main::get( 'parent' )->FileSelect( '-directory' => "./",
													 '-filter' => "*" .
											   ( $opt{ extension } eq "" ? "" :
											   ( ".". $opt{ extension } ) ) );

		unless ( defined( $file = $fs->Show ) ) {
			&main::set( 'block' => 0 );
			return;
		}
	}

	unless ( -f $file and -r $file and $F->open( "<$file" ) ) {
		MBox->show_message( "Can't open file $file for reading.", 1 );
		&main::set( 'block' => 0 );
		return;
	}

	# Get the first line with the type of the game and restart loa

	while ( $line = <$F> ) {
		next if $line =~ /^\s*(#.*)?$/;       # skip comments and empty lines
		if ( $line !~ /^\s*(Normal)|(Scrambled)$/i ) {
			MBox->show_message( "Wrong format of game file $file " .
								"at line $.", 1 );
			$F->close;
			&main::set( 'block' => 0 );
			return;
		}

		Menus->new_game( $line =~ /\s*Normal/i ? 0 : 1 );
		last;
	}

	# Read all the lines in the file and move stones accordingly

	while ( $line = <$F> ) {
		next if $line =~ /^\s*(#.*)?$/;       # skip comments and empty lines

		# Check syntax of line

		if ( $line !~ /$p1|$p2|$p3|$p4|$p5|$p6|$p7/i ) {
			MBox->show_message( "Wrong format in game file $file " .
								"at line $.", 1 );
			$F->close;
			&main::set( 'block' => 0 );
			return;
		}

	    chomp $line;

		# Handling of edit commands

		if ( $line =~ /^$p2|$p3|$p4\s*/i ) {
			handle_edit( $line );
			next;
		}

		# Handling of loa giving up

	    if ( $line =~ /$p5|$p6/i ) {
		    winner( $file, $F, $line );
			return;
		}

		# Handling of end of recorded game

	    if ( $line =~ /$p7/i ) {
			&main::set( 'player' => ( $1 eq "b" ? "black" : "white" ) );
			$F->close;
			return;
		}

		# Handling of 'real' moves: ask loa for its opinion about the move

		$line =~ /$p1\s?$/i;
		my ( $from, $to, $is_capt ) = ( $1, $2, $3 );

		unless ( ( $reply = &main::talk( "move $from $to" ) )
				 !~ /\s*error/i ) {
			MBox->show_message( "Game file $file seems to be corrupted " .
								"at line $.", 1 );
			$F->close;
			&main::set( 'block' => 0 );
			return;
		}

		# Update the move list and move the stone on the board

		$opt{ board }->delete_stone( $to ) if defined $is_capt;
		&MList::update( "move: $from-$to" . ( defined $is_capt ? "+" : " " ) );
		$stone = $opt{ board }->find_stone( $from );
		$stone->pos( $to );
		$stone->coord( $opt{ board }->get_coords( $to ) );
		$stone->draw;
		$opt{ board }->highlight( $from, $to );
		$opt{ canvas }->update;

		# Get remaining comments from loa and check if we have a winner

		while ( $reply !~ /^\s*ok\s*/i ) {
			if ( $reply =~ /\-?5000/ ) {
				&winner( $file, $F );
				return;
			}
			$reply = &main::receive( );
		}

		# Make loa switch sides

		&main::talk( "cc" );
		&main::set( 'player' =>
					( &main::get( 'player' ) =~ /black/i ?
					  'white' : 'black' ) );
		&main::title( &main::get( 'player' ) . "s turn" );
	}

	$F->close;
	&main::set( 'block' => 0 );
}

#---------------------
# Handling for lines from edit mode

sub handle_edit {

	my $line = shift;
	my $add  = '^\s*add\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $del  = '^\s*^del\s+([a-h][1-8])\s+\(((white)|(black))\)';
	my $move = '^\s*move\s+([a-h][1-8])\-([a-h][1-8])\s+\(((white)|(black))\)';

	if ( $line =~ /$add/i ) {
		&main::talk( "setstone $1 $2" );
		$opt{ board }->make_stone( $1, $2 );
		&MList::update( $line );
	} elsif ( $line =~ /$del/i ) {
		&main::talk( "setstone $1 empty" );
		$opt{ board }->delete_stone( $1 );
		&MList::update( $line );
	} else {
		$line =~ /$move/i;
		&main::talk( "setstone $1 empty" );
		$opt{ board }->delete_stone( $1 );
		&main::talk( "setstone $2 $3" );
		$opt{ board }->make_stone( $2, $3 );
		&MList::update( $line );
	}
}

#---------------------
# Handles the case that the loaded game is over

sub winner {

	my ( $file, $F, $line ) = @_;
	my $p1 = '^\s*Human wins\s*\(\s*([23])\s*([bw])\s*\)';
	my $p2 = '^\s*LOA wins\s*\(\s*([14])\s*([bw])\s*\)';
	my $p3 = '^\s*Game over\s*\(\s*5\s*([bw])\s*\)';
	my $p4 = '^\s*LOA gives up\s*\(\s*6\s*([bw])\s*\)';

	# Read loas remaining comments

	unless ( defined $line ) {
		while ( &main::receive( ) !~ /^\s*ok\s*/i ) { }

		# Read line about who won the game

		while ( $line = <$F> ) {
			next if $line =~ /^\s*(#.*)?$/;     # skip comments and empty lines

			unless ( $line =~ /^(Human)|(LOA) wins/i ) {
				&main::set( 'over' => 2 );
				&main::title( "Someone (" . &main::get( 'player' ) .
							  ") has won" );
				MBox->show_message( "Wrong format of game file $file " .
									"at line $.", 1 );
				$F->close;
				&main::set( 'block' => 0 );
				return;
			}
			last;
		}
	}

	# Set the window title and player accordingly

	if ( $line =~ /$p1/i ) {             # human wins
		&main::set( 'over' => $1 );
		&main::set( 'player' => ( $2 eq "b" ? "black" : "white" ) );
		&main::title( "You (" . &main::get( 'player' ) . ") win" );
		&main::talk( "cc" ) if &main::get( 'over' ) == 3;
	} elsif ( $line =~ /$p2/i ) {        # loa wins
		&main::set( 'over' => $1 );
		&main::set( 'player' => ( $2 eq "b" ? "black" : "white" ) );
		&main::title( "Loa (" . ( &main::get( 'player' ) eq "black" ?
								  "white" : "black" ) . ") wins" );
		&main::talk( "cc" ) if &main::get( 'over' ) == 1;
	} elsif ( $line =~ /$p3/i ) {        # game over
		&main::set( 'over' => 5 );
		&main::set( 'player' => ( $1 eq "b" ? "black" : "white" ) );
		&main::title( "Game over" );
	} elsif ( $line =~ /$p4/i ) {        # loa gives up
		&main::set( 'over' => 6 );
		&main::set( 'player' => ( $1 eq "b" ? "black" : "white" ) );
		&main::title( "You (" . &main::get( 'player' ) . ") win" );
	} else {
		MBox->show_message( "$line, Wrong format of game file $file " .
							"at line $.", 1 );
	}

	$F->close;
	&main::set( 'block' => 0 );
	return;
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

1;
