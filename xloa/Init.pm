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

# Package takes care of intitialisation

package Init;
use FileHandle;
use Board;
use Stone;
use MBox;
use CBox;
use Menus;
use EStone;
use Help;
use strict;


# This is the complete list of all user changeable parameters. If they aren't
# set by the user the values from the following hash will be used, so apply
# changes here

my %defaults = (
	size_small      => 400,
	size_large      => 560,
	border          => 20,
	border_x        => 20,    # is calculated later
	border_y        => 20,    # is calculated later
	bs_ratio        => 0.05,  # is calculated later

	colors          => [ 'background', 'stonecolor1', 'stonecolor2',
						 'shadowcolor', 'boardcolor1', 'boardcolor2',
						 'fontcolor', 'movesarrowcolor',
						 'hintarrowcolor', 'highlightcolor' ],

	background      => 'black',
	stonecolor1     => 'black',
	stonecolor2     => 'white',
	boardcolor1     => 'pale green',
	boardcolor2     => 'papaya whip',
	fontcolor       => 'WhiteSmoke',
	movesarrowcolor => 'blue',
	hintarrowcolor  => 'red',
	highlightcolor  => 'gold',

	level           => 3,
	randomize       => 1,
    highlight       => 1,
	alertbell       => 0,
	ringbell        => 0,
	flash           => 0,
	flashes         => 3,
	flashtime       => 0.05,

	fonts           => [ 'font', 'menufont', 'boardfont' ],

	extension       => 'loa',

	is_debug        => 0,
);

# This hash is for the parameters as they are really used - it is set up
# from the defaults (see above) and the user settings

my %opt = ( );


#---------------------
# Main routine to initialize the game

sub init {

	&get_screen_dims( );

	# This has to be done first: I don't know if the default font is really
	# available on all systems so we try two more that really should be there

	if ( $opt{ screen_width } >= 1024 and
		 $opt{ screen_height } > 786 ) {
		$defaults{ font } = '-*-helvetica-bold-r-*--*-140-*';
	} else {
		$defaults{ font } = '-*-helvetica-bold-r-*--*-120-*';
	}

	$defaults{ font } = '6x13' unless &isfont( $defaults{ font } );
	$defaults{ font } = 'fixed' unless &isfont( $defaults{ font } );

	$opt{ is_debug } = $defaults{ is_debug };
	$opt{ prefix } = main::get( 'prefix' );

	&get_options;
	&init_graphic_sizes;
	&color_init;
	&font_init;
	&highlight_init;
	&level_init;
	&random_init;
	&ext_init;
	&advertise_options;
}

#---------------------
# There must be a better way to figure out the screen dimensions but
# I didn't find it yet...

sub get_screen_dims {

	my $F = new FileHandle;

	unless ( $F->open( "xdpyinfo 2>&1 |" ) ) {
		$opt{screen_width }  = 1024;
		$opt{screen_height } =  768;
		return;
	}

	while ( my $line = <$F> ) {
		if ( $line =~ /dimensions:\s*(\d+)x(\d+)/ ) {
			$opt{screen_width }  = $1;
			$opt{screen_height } = $2;
			last;
		}
	}

	$F->close( );

	unless ( defined( $opt{screen_width } ) and 
			 defined( $opt{screen_height } ) ) {
		&main::stop_loa( );
		die "Can't start xloa, X does not seem to be running.\n";
	}
}

#---------------------
# Parses all the configuration files to find out about the users preferences

sub get_options {

    my $F = new FileHandle;

    my $home = ( getpwuid $< )[ 7 ];

	foreach my $file ( "/usr/lib/X11/Xresources",
					   "/usr/lib/X11/app-defaults/Xloa",
					   "$home/.Xresources",
					   "$home/.xloarc" ) {
		if ( $F->open( "$file" ) ) {
			&read_config_file( $file, $F );
			$F->close;
		}
	}
}

#---------------------
# Parses a configuration file

sub read_config_file {

	my ( $file, $fp ) = @_;

	# Set up the patterns of entries we're looking for

	my $pat = '\s*'  .                   # leading white space
			  '(\*|([Xx]loa[\.\*]))' .   # `*' or `Xloa' or `xloa'
	          ( $file =~ /(\.xloarc)|(Xloa)/ ? '*' : '' ) .
                   # optional for ~/.xloarc and /usr/lib/X11/app-defaults/Xloa
			  '(\w+)' .                  # keyword
			  '((\s*\:\s*)|(\s+))' .     # separator
              '(.+)' .                   # value
              '\s*';                     # trailing white space

	# Read in and parse all lines - take care of continued lines, indicated by
	# a backslash as the very last non-whitespace character

    while ( my $line = <$fp> ) {
		while ( $line =~ /^(.+)\\\s*$/ ) {
			$line = $1;
			last unless defined( my $next_line = <$fp> );
			$line .= $next_line;
		}

		if ( $line =~ /^$pat$/ ) {
			my $key = lc( $3 );
			my $val = lc( $7 );
			$val =~ s/\s*$//;            # strip trailing blanks
			$opt{ $key } = $val;
		}
	}
}

#---------------------
# Sets board size and related stuff

sub init_graphic_sizes {

	if ( $opt{ screen_width } >= 1024 and
		 $opt{ screen_height } > 786 ) {
		$opt{ size } = $defaults{ size_large }
			unless exists $opt{ size } and $opt{ size } =~ /^\d+$/;
	} else {
		$opt{ size } = $defaults{ size_small }
			unless exists $opt{ size } and $opt{ size } =~ /^\d+$/;
	}

	$opt{ border } = $defaults{ border }
		unless exists $opt{ border } and $opt{ border } =~ /^\d+$/;
	$opt{ border_x } = $opt{ border_y } = $opt{ border };

	$opt{ bs_ratio } = $opt{ border } / $opt{ size };
}

#---------------------
# Sets a level according to user preference or to a default value

sub level_init {

	 # Evaluate user preference for the game strength level

	 if ( exists $opt{ level } ) {
		 $opt{ level } = 2 if $opt{ level } =~ /^Very\s*Easy$/i;
		 $opt{ level } = 3 if $opt{ level } =~ /^Easy$/i;
		 $opt{ level } = 4 if $opt{ level } =~ /^Medium$/i;
		 $opt{ level } = 5 if $opt{ level } =~ /^Hard$/i;
		 $opt{ level } = 6 if $opt{ level } =~ /^Very\s*Hard$/i;
	 }

	 # Use default level if level is still undefined or invalid

	 if ( exists $opt{ level } and $opt{ level } =~ /[1-5]/ ) {
		 $opt{ level }++;
	 } else {
		 $opt{ level } = $defaults{ level };
	 }
}

#---------------------
# Initializes the variable controlling the random behaviour of loa

sub random_init {

	if ( exists $opt{ randomize } ) {
		if ( $opt{ randomize } =~ /^off$/i
			 or ( $opt{ randomize } =~ /^\d+$/ and $opt{ randomize } == 0 ) ) {
			$opt{ randomize } = 0;
		} else {
			$opt{ randomize } = 1;
		}
	} else {
		$opt{ randomize } = $defaults{ randomize };
	}
}

#---------------------
# Sets the default extension xloa is going to use for save files

sub ext_init {
	$opt{ extension } = $defaults{ extension }
		unless exists $opt{ extension };
}

#---------------------
# Sets the colors while taking into consideration the users wishes

sub color_init {

	# evaluate user preferences for colors or take default values

	foreach my $color ( @{ $defaults{ colors } } ) {
		$opt{ $color } = $defaults{ $color } unless
			exists $opt{ $color } and defined &iscolor( $opt{ $color } );
	}
}

#---------------------
# Checks if a user supplied color is valid - valid are either three-, six-,
# nine- or twelve-digit hex numbers following a `#' or color names fitting
# an entry in the sytems color database file `rgb.txt'.

sub iscolor {

	my $color = shift;
	my $F = new FileHandle;
	my $rgb;
	my $pat = '^\#[A-F0-9]';

	# First check if color is defined as three-, six-, nine or twelve-digit
	# hex value

	return 1 if $color =~ /$pat{3}$/i or $color =~ /$pat{6}$/i
		     or $color =~ /$pat{9}$/i or $color =~ /$pat{12}$/i;
	return undef if $color =~ /^\#/;              # wrong color specification

	# Otherwise open color database and try to match the color name

	return undef unless defined( $rgb = &find_rgb ) and $F->open( "$rgb" );

	while ( <$F> ) {
		/^\s*(\d+\s+){3}(\w+(\s+\w+)*)\s*$/;
		if ( defined $2 and $color =~ /^$2$/i ) {
			$F->close;
			return 1;
		}
	}

	$F->close;
	undef;                                        # color name not found
}

#---------------------
# This routine to locate the systems color database file rgb.txt is mostly
# taken from Mark Summerfields (<summer@perlpress.com>) ColourChooser module.

sub find_rgb {

    foreach ( '/usr/local/lib/X11/rgb.txt',
			  '/usr/lib/X11/rgb.txt',
			  '/usr/local/X11R5/lib/X11/rgb.txt',
			  '/X11/R5/lib/X11/rgb.txt',
			  '/X11/R4/lib/rgb/rgb.txt',
			  '/usr/openwin/lib/X11/rgb.txt',
			  '/usr/X11R6/lib/X11/rgb.txt',
			) {
        return $_ if -e $_ ;
    }

    undef ;
}

#---------------------
# Checks that the fonts the user asks for exist and sets them

sub font_init {

	# Check all fonts the user asks for

	foreach my $font ( @{ $defaults{ fonts } } ) {
		next unless exists $opt{ $font };
		delete $opt{ $font } unless &isfont( $opt{ $font } );
	}

	$opt{ font } = $defaults{ font } unless exists $opt{ font };

	# Use default font if only this is specified

	$opt{ boardfont } = $opt{ font } unless exists $opt{ boardfont };
	$opt{ menufont  } = $opt{ font } unless exists $opt{ menufont };
}

#---------------------
# Checks if the font supplied as an argument is installed on the system

sub isfont {

	my $font = shift;

	# Under UNIX the fonts are checked using `xlsfonts' - we also got to
	# read STDOUT since error messages from xlsfonts go there

	my @xlsfonts = `xlsfonts -o -fn "$font" 2>&1`;
	return $xlsfonts[ 0 ] !~ /unmatched/;
}

#---------------------
# Sets up flashing and hightlighting of moves and bell ringing

sub highlight_init {

	# Set up if there is flashing of moves at all

	if ( exists $opt{ flash } ) {
		if ( $opt{ flash } =~ /^off$/i or
			 ( $opt{ flash } =~ /^\d+$/ and $opt{ flash } == 0 ) ) {
			$opt{ flash } = 0;
		} else {
			$opt{ flash } = 1;
		}
	} else {
		$opt{ flash } = $defaults{ flash };
	}

	# Number of flashes has to be an integer

	if ( exists $opt{ flashes } ) {
		$opt{ flashes } = $defaults{ flashes } if $opt{ flashes } !~ /^\d+$/i;
	} else {
		$opt{ flashes } = $defaults{ flashes };
	}

	# Flash time has to be an integer or a floating point number

	if ( exists $opt{ flashtime } ) {
		$opt{ flashtime } = $defaults{ flashtime }
		    if $opt{ flashtime } !~ /^(\d+\.*\d*)|(\.\d+)$/i;
	} else {
		$opt{ flashtime } = $defaults{ flashtime };
	}

	if ( exists $opt{ highlight } ) {
		if ( $opt{ highlight } =~ /^off$/i
			 or ( $opt{ highlight } =~ /^\d+$/ and $opt{ highlight } == 0 ) ) {
			$opt{ highlight } = 0;
		} else {
			$opt{ highlight } = 1;
		}
	} else {
		$opt{ highlight } = $defaults{ highlight };
	}

	if ( exists $opt{ alertbell } ) {
		if ( $opt{ alertbell } =~ /^off$/i
			 or ( $opt{ alertbell } =~ /^\d+$/ and $opt{ alertbell } == 0 ) ) {
			$opt{ alertbell } = 0;
		} else {
			$opt{ alertbell } = 1;
		}
	} else {
		$opt{ ringbell } = $defaults{ ringbell };
	}
	if ( exists $opt{ ringbell } ) {
		if ( $opt{ ringbell } =~ /^off$/i
			 or ( $opt{ ringbell } =~ /^\d+$/ and $opt{ ringbell } == 0 ) ) {
			$opt{ ringbell } = 0;
		} else {
			$opt{ ringbell } = 1;
		}
	} else {
		$opt{ ringbell } = $defaults{ ringbell };
	}
}

#---------------------
# Tells the other packages about options relevant for them

sub advertise_options {

	Board->set( 'size'            => $opt{ size           },
				'border'          => $opt{ border         },
				'border_x'        => $opt{ border_y       },
				'border_y'        => $opt{ border_x       },
				'bs_ratio'        => $opt{ bs_ratio       },
				'background'      => $opt{ background     },
				'boardcolor1'     => $opt{ boardcolor1    },
				'boardcolor2'     => $opt{ boardcolor2    },
				'fontcolor'       => $opt{ fontcolor      },
				'hintarrowcolor'  => $opt{ hintarrowcolor },
				'highlightcolor'  => $opt{ highlightcolor },
				'boardfont'       => $opt{ boardfont      },
				'highlight'       => $opt{ highlight      },
				'highlightcolor'  => $opt{ highlightcolor }  );

	Stone->set( 'stonecolor1'     => $opt{ stonecolor1     },
				'stonecolor2'     => $opt{ stonecolor2     },
				'movesarrowcolor' => $opt{ movesarrowcolor },
				'flashes'         => $opt{ flashes         },
				'flashtime'       => $opt{ flashtime       }  );

	Menus->set( 'menufont'        => $opt{ menufont  },
				'level'           => $opt{ level     },
				'randomize'       => $opt{ randomize },
				'highlight'       => $opt{ highlight },
				'flash'           => $opt{ flash     },
				'alertbell'       => $opt{ alertbell },
				'ringbell'        => $opt{ ringbell  },
				'is_debug'        => $opt{ is_debug  }  );

	MList->set( 'menufont'        => $opt{ menufont } );

	MBox->set( 'menufont'         => $opt{ menufont } );

	CBox->set( 'menufont'         => $opt{ menufont } );

	EStone->set( 'stonecolor1'    => $opt{ stonecolor1 },
				 'stonecolor2'    => $opt{ stonecolor2 }  );

	Help->set( 'menufont'         => $opt{ menufont },
			   'prefix'           => $opt{ prefix   }  );

	Save->set( 'extension'        => $opt{ extension } );
}

1;
