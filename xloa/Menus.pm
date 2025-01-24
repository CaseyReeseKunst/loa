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

# Obviously, this package takes care of the menus...

package Menus;

use strict;
use Tk;
use Board;
use MList;
use Help;
use Edit;
use Debug;


my %opt = (
    menubar        => undef,
	board          => undef,                 # imported from Board
	canvas         => undef,                 # imported from Board
	menufont       => '-*-helvetica-bold-r-*--*-120-*',
	level          => 4,
	lmval          => 4,
	randomize      => 1,
	random_val     => 1,
	alertbell      => 0,
	ringbell       => 0,
	is_movelist    => 0,
	highlight      => 1,
	flash          => 0,
	edit           => 0,
	is_quit        => 0,
	takeback_block => 0,
    switch_block   => 0,
	is_debug       => 0,
	debug_menu     => undef
);


#---------------------
# Creates the menu and sets key bindings for accelerators

sub init {

	$opt{ menubar } =
	my $menu_bar = &main::get( 'parent' )->Frame( '-borderwidth' => 2
												  )->pack( '-fill' => 'x' );

	# Game menu

	my $game_menu = $menu_bar->Menubutton( '-text' => 'Game',
										   '-underline' => 0,
										   '-tearoff' => 0,
										   '-font' => $opt{ menufont }
										 )->pack( '-side' => 'left' );

	$game_menu->cascade( '-label' => 'New game',
						 '-font' => $opt{ menufont } );
	my $game_sub = $game_menu->cget( '-menu' )->Menu;
	$game_menu->entryconfigure( 'New game',
								'-menu' => $game_sub );
	$game_sub->configure( '-tearoff' => 0 );
	$game_sub->command( '-label' => 'Standard',
						'-accelerator' => 'Ctrl+n',
						'-font' => $opt{ menufont },
						'-command' => [ \&new_game, 0, 'normal' ] );
	$game_sub->command( '-label' => 'Scrambled',
						'-accelerator' => 'Ctrl+N',
						'-font' => $opt{ menufont },
						'-command' => [ \&new_game, 0, 'scrambled' ] );
	&main::get( 'parent' )->bind( 'all', '<Control-n>' =>
								  [ \&new_game, 'normal' ] );
	&main::get( 'parent' )->bind( 'all', '<Control-N>' =>
								  [ \&new_game, 'scrambled' ] );

	$game_menu->separator;

	$game_menu->command( '-label' => 'Switch stones',
						 '-accelerator' => 'Ctrl+s',
						 '-font' => $opt{ menufont },
						 '-command' => \&switch_stones );
	&main::get( 'parent' )->bind( 'all', '<Control-s>' => \&switch_stones );

	$game_menu->command( '-label' => 'Undo last move',
						 '-accelerator' => 'Delete',
						 '-font' => $opt{ menufont },
						 '-command' => \&take_back );
	&main::get( 'parent' )->bind( &main::get( 'parent' ),
								 '<Delete>'=> \&take_back );
	&main::get( 'parent' )->bind( &main::get( 'parent' ),
								  '<BackSpace>' => \&take_back );

	$game_menu->separator;

	$game_menu->command( '-label' => 'Save game',
						 '-font' => $opt{ menufont },
						 '-command' => \&Save::save );
	$game_menu->command( '-label' => 'Load game',
						 '-font' => $opt{ menufont },
						 '-command' => \&Save::load );
	$game_menu->separator;

	$game_menu->command( '-label' => 'Quit',
						 '-accelerator' => 'Ctrl+q',
						 '-font' => $opt{ menufont },
						 '-command' => \&quit );
	&main::get( 'parent' )->bind( 'all', '<Control-q>' => \&quit );

	# Level menu

	my $level_menu = $menu_bar->Menubutton( '-text' => 'Level',
											'-tearoff' => 0,
											'-underline' => 0,
											'-font' => $opt{ menufont }
										  )->pack( '-side' => 'left' );

	$level_menu->radiobutton( '-label' => 'Extremely easy',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 2 );

	$level_menu->radiobutton( '-label' => 'Very easy',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 3 );

	$level_menu->radiobutton( '-label' => 'Easy',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 4 );

	$level_menu->radiobutton( '-label' => 'Medium',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 5 );

	$level_menu->radiobutton( '-label' => 'Hard',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 6 );

	$level_menu->radiobutton( '-label' => 'Very hard',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 7 );

	$level_menu->radiobutton( '-label' => 'Extremely hard',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 8 );

	$level_menu->radiobutton( '-label' => 'Insane',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_level,
							  '-variable' => \$opt{ lmval },
							  '-value' => 9 );

	$level_menu->separator;

	$level_menu->checkbutton( '-label' => 'Randomize',
							  '-font' => $opt{ menufont },
							  '-command' => \&set_random,
							  '-variable' => \$opt{ random_val }
	                        );

	# Options menu

	my $options_menu = $menu_bar->Menubutton( '-text' => 'Options',
											  '-underline' => 0,
											  '-tearoff' => 0,
											  '-font' => $opt{ menufont }
											 )->pack( '-side' => 'left' );

	$options_menu->checkbutton( '-label' => 'Show move list',
								'-accelerator' => 'Ctrl+m',
								'-font' => $opt{ menufont },
								'-command' => \&MList::show,
								'-variable' => \$opt{ is_movelist } );
	&main::get( 'parent' )->bind( 'all', '<Control-m>' =>, \&MList::show );

	$options_menu->checkbutton( '-label' => 'Edit board',
								'-accelerator' => 'Ctrl+e',
								'-font' => $opt{ menufont },
								'-command' => \&Edit::edit,
								'-variable' => \$opt{ edit } );

	&main::get( 'parent' )->bind( 'all', '<Control-e>' => \&Edit::edit );

	$options_menu->separator;

	$options_menu->checkbutton( '-label' => 'Highlight last move',
								'-accelerator' => 'Ctrl+h',
								'-font' => $opt{ menufont },
								'-variable' => \$opt{ highlight },
								'-command' => \&Board::toggle_highlight );
	&main::get( 'parent' )->bind( 'all', '<Control-h>' =>
								  \&Board::toggle_highlight );

	$options_menu->checkbutton( '-label' => 'Flash moves',
								'-accelerator' => 'Ctrl+f',
								'-font' => $opt{ menufont },
								'-variable' => \$opt{ flash } );
	&main::get( 'parent' )->bind( 'all', '<Control-f>' =>
								  sub { $opt{ flash } ^= 1 } );

	$options_menu->checkbutton( '-label' => 'Ring bell after moves',
								'-accelerator' => 'Ctrl+r',
								'-font' => $opt{ menufont },
								'-variable' => \$opt{ alertbell } );
	&main::get( 'parent' )->bind( 'all', '<Control-r>' =>
								  sub { $opt{ alertbell } ^= 1 } );

	$options_menu->checkbutton( '-label' => 'Ring bell on errors',
								'-accelerator' => 'Ctrl+R',
								'-font' => $opt{ menufont },
								'-variable' => \$opt{ ringbell } );
	&main::get( 'parent' )->bind( 'all', '<Control-R>' =>
								  sub { $opt{ ringbell } ^= 1 } );

	# Handling of debug menu....

	if ( $opt{ is_debug } ) {
		$opt{ is_debug } = 0;
		&debug_menu;
	}
	&main::get( 'parent' )->bind( 'all', '<Alt-Control-D>' => \&debug_menu );

	# Help menu

	my $help_menu = $menu_bar->Menubutton( '-text' => 'Help',
										   '-underline' => 0,
										   '-tearoff' => 0,
										   '-font' => $opt{ menufont }
										 )->pack( '-side' => 'right' );

	$help_menu->command( '-label' => 'Rules of LOA',
						 '-font' => $opt{ menufont },
						 '-command' => [ \&Help::help, 'rules' ] );
	$help_menu->command( '-label' => 'Using xloa',
						 '-font' => $opt{ menufont },
						 '-command' => [ \&Help::help, 'using' ] );
	$help_menu->command( '-label' => 'Copying',
						 '-font' => $opt{ menufont },
						 '-command' => [ \&Help::help, 'copy' ] );
	$help_menu->command( '-label' => 'About',
						 '-font' => $opt{ menufont },
						 '-command' => [ \&Help::help, 'about' ] );
}


#---------------------
# Create or delete the debug menu

sub debug_menu {

	my $menu_bar = $opt{ menubar };

	if ( $opt{ is_debug } == 0 ) {
		my $debug_menu =
			$opt{ debug_menu } = $menu_bar->Menubutton( '-text' => 'Debug',
										                '-underline' => 0,
														'-tearoff' => 0,
														'-font' =>
														      $opt{ menufont }
												  )->pack( '-side' => 'left' );

		$debug_menu->command( '-label' => 'Show',
							  '-font' => $opt{ menufont },
							  '-command' => \&Debug::show );

		$debug_menu->command( '-label' => "Don't print",
							  '-font' => $opt{ menufont },
							  '-command' => [ \&main::set,
											  'debug_lebel' => 0 ] );

		$debug_menu->command( '-label' => 'Print moves',
							  '-font' => $opt{ menufont },
							  '-command' => [ \&main::set,
											  'debug_level' => 1 ] );

		$debug_menu->command( '-label' => 'Show all replies',
							  '-font' => $opt{ menufont },
							  '-command' => [ \&main::set,
											  'debug_level' => 2 ] );

		$debug_menu->command( '-label' => 'Full debug',
							  '-font' => $opt{ menufont },
							  '-command' => [ \&main::set,
											  'debug_level' => 4 ] );

		$debug_menu->separator;

		$debug_menu->command( '-label' => 'Talk to loa',
							  '-font' => $opt{ menufont },
							  '-command' => \&Debug::talk_to_loa );
		$opt{ is_debug } = 1;
	} else {
		$opt{ debug_menu }->destroy;
		$opt{ is_debug } = 0;
		&main::set( 'debug_level' => 0 );
	}
}

#---------------------
# Starts a new game - `loa' is restarted and board and stones are redrawn

sub new_game {

	return if &main::get( 'mess_block' ) or &main::get( 'dont_break' );

	&main::get( 'parent' )->fileevent( &main::get( 'pin' ), "readable" => "" );
	&Menus::set( over => 8, switch_block => 1 );
	&main::get( 'parent' )->bind( 'all', '<Control-s>' => "" );

	# stop and restart loa

	&main::stop_loa;
	&main::start_loa;

	# Set up a scrambled game if the user asked for it

	if ( $_[ 1 ] eq "scrambled" ) {
		&main::talk( "layout 1" );
		&main::set( 'is_scrambled' => 1 );
	} else {
		&main::set( 'is_scrambled' => 0 );
	}

	# Clear the move list

	&MList::update( 'clear' );

	# Redraw board with stones

	&main::title( "blacks turn" );
	Stone->get( 'canvas' )->configure( '-cursor' => 'top_left_arrow' );
	$opt{ board }->draw;
	$opt{ board }->highlight;

	# Set level and randomize state from last game

	&set_level( $opt{ level } );
	&set_random( );

	$opt{ canvas }->Unbusy;

	&Menus::set( switch_block => 0 );
	&main::get( 'parent' )->bind( 'all', '<Control-s>' => \&switch_stones );
}

#---------------------
# Switches sides: the user gets the white stones and the computer the black
# ones (or just the other way round) - if called with just one argument (this
# is a callback routine, so it automatically gets one argument) the computer
# also makes the next move, but if called with a second argument, the routine
# returns immediately after making the switch

sub switch_stones {

	return if &main::get( 'block' );
	return if &main::get( 'over' );
	return if &main::get( 'edit' );

	return if $opt{ switch_block };
	&main::set( 'dont_break' => 1 );
	&Menus::set( switch_block => 1 );

	&main::set( 'block' => 1 );

	&Stone::show_moves( $opt{ canvas } );
	&Board::show_hint( $opt{ canvas } );

	# Tell loa to switch stones

	my $reply = &main::talk( "cc" );
	$reply =~ /^\s*ok\s*$/i or
		die "loa doesn't like to switch colors and says: $reply";

	# Remember that we now got the other stones

	if ( &main::get( 'player' ) eq 'white' ) {
		&main::set( 'player' => 'black' );
	} else {
		&main::set( 'player' => 'white' );
	}

	# Finally ask loa to play

	Stone->play;
}

#---------------------
# Here everything necessary is done to end the program

sub quit {

	return if $opt{ is_quit };       # don't do it twice....
	$opt{ is_quit } = 1;
	&main::stop_loa;
	&main::get( 'parent' )->destroy;
	exit;
}

#---------------------
# Tells the program to use a different level passed as the argument

sub set_level {

	if ( &main::get( 'block' ) ) {
		$opt{ lmval } = $opt{ level };
		$opt{ canvas }->bell if $opt{ ringbell };
		return;
	}

	&main::talk( "level $opt{ lmval }" ) =~ /^\s*ok\s*$/ or
		die "Wrong level: $opt{ lmval }";
	$opt{ level } = $opt{ lmval };
}

#---------------------
# Sets loa to use deterministic or non-deterministic playing depending on
# the value of the variable $opt{ randomize }

sub set_random {

	if ( &main::get( 'block' ) ) {
		$opt{ random_val } = $opt{ randomize };
		$opt{ canvas }->bell if $opt{ ringbell };
		return;
	}

	&main::talk( "use_rand $opt{ random_val }" );
	$opt{ randomize } = $opt{ random_val };
}

#---------------------
# Takes back the last move (actually, in most cases, two half moves)

sub take_back {

	my $err;

	return if &MList::length == 0;
	return if &main::get( 'block' );
	return if $opt{ takeback_block };

	$opt{ takeback_block } = 1;          # block further undos while we're busy

	# Delete move and hint arrows

	&Stone::show_moves( $opt{ canvas } );
	&Board::show_hint( $opt{ canvas } );

	# If the last move was a move in edit mode just take it back without
	# asking loa to do it - it doesn't know how to handle this

	if ( &MList::last_is_edit ) {
		&undo_edit;
		&MList::update( 'delete' );
	} else {

		# Ask loa to undo the last half move and delete it from the move list

		return if &main::talk( "takeback" ) !~ /^\s*ok\s*$/;
		&MList::update( 'delete' );

		# If the human made the last game finishing move we're done

		unless ( &main::get( 'over' ) == 2 or &main::get( 'over' ) == 4 )
		{
			if ( MList::length != 0 and not &MList::last_is_edit ) {
				&main::talk( "takeback" ) =~ /^\s*ok/i or
					die "Something is really strange after 'takeback'!";
				&MList::update( 'delete' );
			}
			else {
				&change_sides;
			}
		}
	}

	$opt{ board }->draw_stones( );                   # recreate the stones
	&main::title( &main::get( 'player' ) . " turn" );
	&main::set( 'over' => 0 );                       # game is not over yet

	if ( &main::get( 'edit' ) ) {
		&Edit::make_estone( 'black', Edit->get( 'ecanvas' ) );
		&Edit::make_estone( 'white', Edit->get( 'ecanvas' ) );
	}

	if ( &MList::length == 0 or &main::get( 'edit' ) or     # set highlighting
		 &MList::last_is_edit ) {
		$opt{ board }->highlight;
	} else {
		&MList::thelast =~ /([a-z][1-8])\-([a-z][1-8])/i;
		$opt{ board }->highlight( $1, $2 );
	}

	$opt{ takeback_block } = 0;
}

#---------------------
# Takes back the last move if it was done in edit mode

sub undo_edit {

	my $thelast = &MList::thelast;

	if ( $thelast =~ /^add\s+([a-h][1-8])\s+\(((white)|(black))\)/i ) {
		&main::talk( "setstone $1 empty" );
	} elsif ( $thelast =~ /^del\s+([a-h][1-8])\s+\(((white)|(black))\)/i ) {
		&main::talk( "setstone $1 $2" );
	} else {
		$thelast =~
			/^move ([a-h][1-8])\-([a-h][1-8])\s+\(((white)|(black))\)/i;
		&main::talk( "setstone $2 empty" );
		&main::talk( "setstone $1 $3" );
	}
}

#---------------------
# Switches the color of the stones of human and loa

sub change_sides {
	&main::talk( "cc" ) ;
	&main::set( 'player' => ( &main::get( 'player' ) eq 'white' ?
							  'black' : 'white' ) );
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
