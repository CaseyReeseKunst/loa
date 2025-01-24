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

# Package for displaying the help windows

package Help;
use strict;
use FileHandle;
use Tk;
require Tk::ROText;


my %opt = (
	prefix   => "./",
	rules    => { win   => undef,
				  file  => 'rules.txt',
				  title => 'LOAs rules' },
	using    => { win   => undef,
				  file  => 'using.txt',
				  title => 'Using Xloa' },
	copy     => { win   => undef,
				  file  => 'COPYING.txt',
				  title => 'Copying Loa and Xloa' },
	about    => { win   => undef,
				  file  => 'about.txt',
				  title => 'About Loa and Xloa' },
	menufont => '-*-helvetica-bold-r-*--*-120-*',
);

my %defaults = (
	need_scroll => 1,
	tabwidth    => 20,       # in points, for display of tab chars
	width       => 70,       # width of window, in chars
	height      => 36,       # height of window, in lines
	C_padx      => 180,      # padding for Close button
	C_pady      => 10,
	P_padx      => 50,       # padding for pictures
	P_pady      => 15
);


#---------------------
# Diplays one of the help texts depending on the argument: Valid arguments are
# either 'rules', 'using', 'copy' or 'about'. The files tith the help texts
# have to start with a line starting with a '#', possibly followed by the
# width to display tab characters (in dots), the width for displaying the
# texts (as the number of '0'-characters to be shown in one line), the height
# as number of lines in the window and finally the x- and-y padding for the
# Close- Button (in dots). All remaining lines in the file are printed in the
# help window with the only exception of lines starting with a '#', which have
# to contain the name of a picture file to be displayed at the current
# position, followed by the x- and y-padding for the picture.

sub help {

	my $text;
	my $T = new FileHandle;
	my $which = shift;
	return unless defined $opt{ $which };         # check validity of argument

	# Just raise help window if it's already shown

	if ( defined ${ $opt{ $which } }{ win } ) {
		${ $opt{ $which } }{ win }->raise;
		return;
	}

	# Try to open the text file, get size infos from first line and set
	# defaults values if necessary

	$opt{ prefix } .= "/" unless $opt{ prefix } =~ /\/$/;
	return unless $T->open( $opt{ prefix } . ${ $opt{ $which } }{ file } );
	my ( $dummy, $need_scroll, $t, $w, $h, $px, $py ) = split /\s+/, <$T>;
	if ( $dummy ne "#" ) {
		$T->close;
		MBox->show_message( "Wrong format of help file " .
							${ $opt{ $which } }{ file }, 1 );
		return;
	}

	$need_scroll = $defaults{ need_scroll } unless defined $need_scroll;
	$t           = $defaults{ tabwidth    } unless defined $t;
	$w           = $defaults{ width       } unless defined $w;
	$h           = $defaults{ height      } unless defined $h;
	$px          = $defaults{ C_padx      } unless defined $px;
	$py          = $defaults{ C_pady      } unless defined $py;

	# Create a new help window

	my $win = ${ $opt{ $which } }{ win } =
		&main::get( 'parent' )->Toplevel( '-title' =>
										  ${ $opt{ $which } }{ title } );

	# Create the text object

	if ( $need_scroll == 1 ) {
		$text = $win->Scrolled( 'ROText',
								'takefocus' => 1,
								'-wrap' => 'none',
								'-tabs' => $t,
								'-background' => 'white',
								'-width' => $w,
								'-height' => $h,
								'-font' => $opt{ menufont },
								'-scrollbars' => 'oe'
							   )->pack( '-fill' => 'both',
										'-expand' => 1 );
	} else {
		$text = $win->ROText ( 'takefocus' => 1,
							   '-wrap' => 'none',
							   '-tabs' => $t,
							   '-background' => 'white',
							   '-width' => $w,
							   '-height' => $h,
							   '-font' => $opt{ menufont },
							  )->pack( '-fill' => 'both',
									   '-expand' => 1 );
	}

	# Now read the text and insert it - take care about embedded pictures

	my $l = "";
	while ( <$T> ) {
		if ( /^\s*\#/ ) {                      # format line
			$text->insert( 'end', $l ) if ( $l ne "" );
			( $dummy, my $f, my $fpx, my $fpy ) = split /\s+/;
			$fpx = $defaults{ P_padx } unless defined $fpx;
			$fpy = $defaults{ P_pady } unless defined $fpy;
			my $pic = $opt{ prefix } . $f;
			$text->imageCreate( 'end',
								'-image' => $text->Photo( '-file' => $pic ),
														  '-padx' => $fpx,
														  '-pady' => $fpy )
				if defined( $pic ) and -r $pic;     # files has to be readable
			$l = "";
		} else {                               # normal text line
			$l .= $_;
		}
	}

	$text->insert( 'end', $l ) if ( $l ne "" );
    $T->close;

	# Finally add the close button

	$text->windowCreate( 'end',
						 '-window' => $text->Button( '-text' => "Close",
													 '-font' =>
													 $opt{ menufont },
													 '-command' =>
									 sub  { $win->destroy;
											undef ${ $opt{ $which } }{ win } },
											  '-cursor' => 'top_left_arrow' ),
						'-padx' => $px,
						'-pady' => $py );

	# Bind both return keys (if the help window has the focus) as well as the
	# Destroy event to the close buttons command

	$win->bind( '<Destroy>'  => sub { $win->destroy;
									  undef ${ $opt{ $which } }{ win } } );
	$win->bind( '<Return>'   => sub { $win->destroy;
									  undef ${ $opt{ $which } }{ win } } );
	$win->bind( '<KP_Enter>' => sub { $win->destroy;
									  undef ${ $opt{ $which } }{ win } } );
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
# Returns the value of one of the global data of the package

sub get {

	shift;
	my $key = shift;
	return $opt{ $key };
}

1;
