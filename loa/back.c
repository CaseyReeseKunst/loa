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

   RCS: $Id: back.c,v 1.17 2001/12/24 23:19:20 christian Exp christian $
 */


#include "back.h"
#ifndef HAVE_LIMITS_H
    #define INT_MAX 10000
    #define INT_MIN -10000
#else
     #include <limits.h>
#endif     
#include <stdlib.h>

extern BOOLEAN use_rand;


int nfound = 0;			/* number of moves with the same value */

static BOOLEAN(*next_move_ptr) ();	/* Pointer to function: Makenext_move_ptr */
static BOOLEAN(*comp_to_move_ptr) ();	/* Return if it's computers turn */
static void (*take_back_ptr) ();	/* take back last move */
static void (*mark_move_ptr) (int);	/* mark current move */
static int (*evaluate_pos_ptr) ();	/* evaluate current position */


int AlphaBeta(int Depth, int Alpha, int Beta);


/*  This is the traditional minimax search algorithm.
 */
int min_max(int search_depth, BOOLEAN(*CoToMo) (), BOOLEAN(*NeMo) (), void (*TaBa) (), \
	    void (*MaMo) (int), int (*EvPo) ())
{
    comp_to_move_ptr = CoToMo;	/* function that returns "true" if computers turn */
    next_move_ptr = NeMo;	/* make next move, return "false" if not possible */
    take_back_ptr = TaBa;	/* take back */
    mark_move_ptr = MaMo;	/* mark the last move */
    evaluate_pos_ptr = EvPo;	/* evaluate the current position */

    return AlphaBeta(search_depth, INT_MIN + 20, INT_MAX - 20);
}

int AlphaBeta(int Depth, int Alpha, int Beta)
{
    int m, n;
    extern int nfound;

    BOOLEAN Termin;

    Termin = TRUE;
    m = 0;
    if (Depth != 0) {
	if (comp_to_move_ptr()) {
	    m = Alpha;
	    while ((m < Beta) && next_move_ptr()) {
		Termin = FALSE;
		n = AlphaBeta(Depth - 1, m - 1, Beta);
		take_back_ptr();
		if (n > m) {
		    m = n;
		    mark_move_ptr(m);
		    nfound = 1;
		} else if (use_rand && (n == m) && ((rand() % (nfound + 1)) == 0) && (n < 5000)) {
		    mark_move_ptr(m);
		    nfound++;
		}
	    }
	} else {
	    m = Beta;
	    while ((m > Alpha) && next_move_ptr()) {
		Termin = FALSE;
		n = AlphaBeta(Depth - 1, Alpha, m + 1);
		take_back_ptr();
		if (n < m) {
		    m = n;
		    mark_move_ptr(m);
		    nfound = 1;
		} else if (use_rand && (n == m) && ((rand() % (nfound + 1)) == 0) && (n > (-5000))) {
		    mark_move_ptr(m);
		    nfound++;
		}
	    }
	}
    }
    if (Termin) {
	return evaluate_pos_ptr();
    } else {
	return m;
    }
}
