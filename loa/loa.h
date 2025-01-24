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

   RCS: $Id: loa.h,v 1.17 2001/12/24 18:58:59 christian Exp christian $
 */

/* loa.h - important functions for loa */

#ifndef LOA_H
#define LOA_H

#include "gamebase.h"

void clear_board(void);
void setup_initpos(void);
void take_back_stack(void);
int evaluate1(void);
int evaluate2(void);
void gen_movelist(int curr_color, move_list * ZL, BOOLEAN Test, BOOLEAN sort_opt);
void mark_move(int W);
BOOLEAN next_move(void);
BOOLEAN legal_move(l_move Z);
void get_best_move(l_move * Z);
void make_move(l_move z);
void computer_move(void);
void update_fields(int Dran, l_move new_move);
void take_back(void);
int central_pos(void);
void scrambled(void);
int count_stones(int color);

extern BOOLEAN progress;

#endif
