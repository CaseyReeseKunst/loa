/*
   loa - a board game
   Copyright (C) 2000 Christian Weninger and Jens Thoms Toerring

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   To contact the authors send emails to
   cweninger@gillion.de                  (Christian Weninger)
   Jens.Toerring@physik.fu-berlin.de  (Jens Thoms Toerring)

   RCS: $Id: modula.h,v 1.8 2001/12/24 19:03:06 christian Exp christian $
 */

/* modula.h - I wrote the original program in Modula-2. To convert the
   program from Modula to C, some defines are useful ... */

#ifndef MODULA_H
#define MODULA_H


#define BOOLEAN int
#define TRUE 1
#define FALSE 0

#define BITSET unsigned int
#define INCL(x,y) x = (x | (1<<y))

/* ACHTUNG !  IN(x,y) bedeutet: y IN x ! */
#define IN(x,y) (x & (1<<y))

#endif
