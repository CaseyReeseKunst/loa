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

   RCS: $Id: olib.h,v 1.6 2001/12/24 19:07:30 christian Exp christian $
 */

#ifndef OLIB_H
#define OLIB_H

#include "gamebase.h"

/* Datastructure for the (very simple) opening-library. There is one main 
   list which contains the first moves. Each move points to a list of replys. */

struct mnode {
    l_move move;
    int value;
    struct mnode *replys;	/* Pointer to list with replys to this move */
    struct mnode *next;		/* Pointer to next move in this list */
};

void new_sequence(const char *mystr);
void init_lib(void);
int get_move(l_move * m);
void check_move(l_move m);

#endif
