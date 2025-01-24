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

   RCS: $Id: gamebase.h,v 1.17.1.1 2002/01/10 22:10:00 christian Exp christian $

 */

#ifndef GAMEBASE_H
#define GAMEBASE_H

/* gamebase.h - basic definitions for the game */

#include "modula.h"

#define MAXFIELDS 8
#define MAXDEPTH 9
#define EMPTY 0
#define MAX_ROWS 7
#define MAX_COLS 7
#define BOARD_SIZE (MAXFIELDS * MAXFIELDS * sizeof( int ))
#define MAXPOINTS 5000
#define WHITE 2
#define BLACK 1
#define MAXMOVES 128
/* define an invalid move value */
#define LOA_NOVAL -10000


typedef int board[MAXFIELDS][MAXFIELDS];


typedef struct {
    int row;
    int column;
    int dest_row;
    int dest_col;
    int move_value;
} l_move;

typedef struct {
    int nr_moves;
    l_move moves[96];
} move_list;

typedef struct {
    BOOLEAN first_move;
    l_move last_move;
    board the_board;
    int move_nr;
    move_list Zl;
    int to_move;
} state;

typedef struct {
    int board_size;
    int move_no;
    int level;
    int opponent[3];
    board current_board;
    BOOLEAN First;
    board history[MAXMOVES];
    move_list ZL;
    int movelist_valid;
    int comp_move; /* true while computer's turn is calculated */
    int whose_turn;
    int beginner;
    int stk_ptr;
    state game_stack[MAXDEPTH];
    l_move best_moves[MAXDEPTH][MAXDEPTH];
    int marked[MAXDEPTH];
    int depth;
} game_struct;


void init_game_stack(void);

int num_stones(int);

void ini_struct(void);

void swap_colors(void);

extern int c_color;
extern int h_color;

extern game_struct game;
extern game_struct init_struct;

#endif
