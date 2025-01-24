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

   RCS: $Id: back.h,v 1.9 2001/12/24 18:50:23 christian Exp christian $
 */

/* back.h
 */

#include "modula.h"

#ifndef BACK_H
#define BACK_H



      

/* Parameter: 
   1. search_depth
   2. comp_to_move_ptr(): BOOLEAN        True, if it is loa's turn
   3. next_move_ptr(): BOOLEAN          Make next move, true if successful
   4. take_back_ptr()                   Take back the last move
   5. mark_move_ptr(int)                Mark the last move
   6. evaluate_pos_ptr(): int           Evaluate the current position
 */

int min_max(int search_depth, BOOLEAN(*comp_to_move_ptr) (), BOOLEAN(*next_move_ptr) (),
	    void (*take_back_ptr) (), void (*mark_move_ptr) (int), int (*evaluate_pos_ptr) ());


#endif
