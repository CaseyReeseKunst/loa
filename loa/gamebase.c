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

   RCS: $Id: gamebase.c,v 1.15.1.1 2002/01/10 21:58:58 christian Exp christian $
 */

#include "gamebase.h"

void init_game_stack(void)
{
    game.stk_ptr = 0;
    game.game_stack[0].to_move = c_color;
    game.marked[0] = 0;
    game.movelist_valid = 0;
    game.comp_move = 0;
}

int num_stones(int wer)
{
    int i, j, z;

    z = 0;
    for (i = 0; i < game.board_size; i++) {
	for (j = 0; j < game.board_size; j++) {
	    if (game.current_board[i][j] == wer)
		z++;
	}
    }
    return z;
}

void ini_struct(void)
{
    int i, j;

    c_color = WHITE;
    h_color = BLACK;
    init_struct.board_size = 8;
    init_struct.level = 3;
    init_struct.depth = 3;
    init_struct.move_no = 0;
    init_struct.movelist_valid = 0;
    for (i = 0; i < init_struct.board_size; i++) {
	for (j = 0; j < init_struct.board_size; j++) {
	    init_struct.current_board[i][j] = EMPTY;
	}
    }
    init_struct.opponent[h_color] = c_color;
    init_struct.opponent[c_color] = h_color;
}

void swap_colors(void)
{
    if (c_color == WHITE) {
	c_color = BLACK;
	h_color = WHITE;
    } else {
	c_color = WHITE;
	h_color = BLACK;
    }
}
