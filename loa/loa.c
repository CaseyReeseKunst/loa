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

   RCS: $Id: loa.c,v 1.37.1.1 2002/01/10 21:23:40 christian Exp christian $
 */

#include "back.h"
#include "loa.h"
#include "matrix.h"
#include <string.h>
#include <stdio.h>



static void calc_dest(int s, int z, int *zs, int *zz, int dist, int direct);
static BOOLEAN is_legal(int s, int z, int zs, int zz);
static int cnt_stones(int s, int z, int direct);
static void sort_list(move_list * mvlist);
static void bsort_list(move_list * movelist);
static void del_vals(move_list * mvlist);
static void note_move(int s, int z, int zs, int zz);
static void new_value(l_move Z, move_list * L);
BOOLEAN comps_turn(void);
static int power(int base, int n);
static void show_state(void);
static void print_move(l_move m);
static void print_mvlist(move_list ml);
static int curr_color;		/* must be set by gen_movelist */
static move_list *mvlist;	/* must be set by gen_movelist */

enum line {
    diag1, diag2, waag, senk
};


/*
   clear_board - remove all stones from the board
 */
void clear_board(void)
{
    int i, j;

    for (i = 0; i < MAXFIELDS; i++) {
	for (j = 0; j < MAXFIELDS; j++) {
	    game.current_board[i][j] = EMPTY;
	}
    }
}



/*
   Set up initial position
 */
void setup_initpos(void)
{
    int i, j;

    for (j = 1; j < 7; j++) {
	game.current_board[0][j] = c_color;
	game.current_board[7][j] = c_color;
    }
    for (i = 1; i < 7; i++) {
	game.current_board[i][0] = h_color;
	game.current_board[i][7] = h_color;
    }
    gen_ini_matrix();   /* seems to be the wrong place for this */
}



/*
   An alternative initial position
 */
void scrambled(void)
{
    int i, j, akt;

    akt = c_color;
    for (j = 1; j < 7; j++) {
	game.current_board[0][j] = akt;
	game.current_board[7][j] = (akt == c_color) ? h_color : c_color;
	if (akt == c_color) {
	    akt = h_color;
	} else {
	    akt = c_color;
	}
    }
    for (i = 1; i < 7; i++) {
	game.current_board[i][0] = (akt == c_color) ? h_color : c_color;
	game.current_board[i][7] = akt;
	if (akt == c_color) {
	    akt = h_color;
	} else {
	    akt = c_color;
	}
    }
}



/*
   Show progress.
 */
void show_state(void)
{
    if (progress) {
	printf("calculated: %d of %d\n", game.game_stack[0].move_nr, game.game_stack[0].Zl.nr_moves);
	fflush(stdout);
    }
}


void print_move(l_move m)
{
    char mv[6];
    mv[0] = m.column + 'a';
    mv[1] = m.row + '1';
    mv[2] = ' ';
    mv[3] = m.dest_col + 'a';
    mv[4] = m.dest_row + '1';
    mv[5] = '\0';
    printf("%s", mv);
}

/* This helps debugging */
void print_mvlist(move_list ml)
{
    int i;
    for (i = 0; i < ml.nr_moves; i++) {
        print_move(ml.moves[i]); printf("%s%d%s", " (", ml.moves[i].move_value, ")"); printf(" - ");
    }
    printf("\n");
}

/*
   Make next move (from movelist). 
 */
BOOLEAN next_move(void)
{
    if (game.game_stack[game.stk_ptr].first_move) {
	game.game_stack[game.stk_ptr].move_nr = 0;
	game.game_stack[game.stk_ptr].first_move = FALSE;
	if (abs(evaluate1()) >= MAXPOINTS) {
	    return FALSE;
	}
    } else {
	(game.game_stack[game.stk_ptr].move_nr)++;
    }
    if (game.game_stack[game.stk_ptr].move_nr >= game.game_stack[game.stk_ptr].Zl.nr_moves) {
	return FALSE;
    } else {
	memcpy(game.game_stack[game.stk_ptr].the_board, game.current_board, BOARD_SIZE);
	game.game_stack[game.stk_ptr].last_move =
	    game.game_stack[game.stk_ptr].Zl.moves[game.game_stack[game.stk_ptr].move_nr];
	update_fields(game.game_stack[game.stk_ptr].to_move,
		      game.game_stack[game.stk_ptr].last_move);
	game.game_stack[game.stk_ptr + 1].to_move =
	    game.opponent[game.game_stack[game.stk_ptr].to_move];
	if (game.stk_ptr == 0)
	    show_state();
    }
    (game.stk_ptr)++;
    game.marked[game.stk_ptr] = 0;
    return TRUE;
}



/*
   evaluate current position. There are two evaluation functions. This one is
   used for preselection and to check whether the game is over.
 */
int evaluate1(void)
{
    int mw, ms;

    mw = group_distance(game.whose_turn);
    ms = group_distance(game.opponent[game.whose_turn]);
    if (mw == 0) {
	if (game.whose_turn == c_color) {
	    return MAXPOINTS;
	} else {
	    return -MAXPOINTS;
	}
    }
    if (ms == 0) {
	if (game.whose_turn == c_color) {
	    return -MAXPOINTS;
	} else {
	    return MAXPOINTS;
	}
    }
    if (game.whose_turn == c_color) {
	return ((ms - mw) + 5 * central_pos());
    } else {
	return ((mw - ms) + 5 * central_pos());
    }
    return central_pos();
}



/*
   evaluate the current position. A high value indicates a good position for
   the computer, a low (negative) value indicates a good position for the human
   player. The computer always plays with c_color.
 */
int evaluate2(void)
{
    extern int gw, defend, use_anzgr, use_movelist, use_preview, dist0, mf;
    extern int sum_dist, use_numstones;
    int res;
    matrix_value WW, WS;
    move_list zlw, zls;

    get_matrix_value(c_color, &WW);
    get_matrix_value(h_color, &WS);
    if (WW.num_groups == 1) {
	return MAXPOINTS;	/* c_color (computer) wins */
    }
    if (WS.num_groups == 1) {
	return -MAXPOINTS;	/* h_color (human) wins */
    }
    res = (gw * (WS.group_value - WW.group_value) + dist0 * (WW.zero_dist) + mf * central_pos());
    if (sum_dist) {
	res = res + sum_dist * (WS.sumdist / WS.num_stones) - sum_dist * (WW.sumdist / WW.num_stones);
    }
    if (use_anzgr) {
	/* include the number of groups in the evaluation */
	res = res + use_anzgr * (WS.num_groups - WW.num_groups);
    }
    if ((defend > 0) && (WS.num_stones > WW.num_stones)) {
	res = (res - power(WS.num_stones - WW.num_stones, defend));
    }
    if (use_numstones) {
	res = res + 5 * use_numstones * (WW.num_stones - WS.num_stones);
    }
    if (use_movelist) {
	/* include the number of possible moves in the evaluation. This is time consuming
	   and therefore only used in low levels */
	    if (game.level < 4) {
	        gen_movelist(c_color, &zlw, FALSE, FALSE);
	        gen_movelist(h_color, &zls, FALSE, FALSE);
	        res = res + 4 * (zlw.nr_moves - zls.nr_moves);
	    }
    }
    return res;
}


/*
   check if Z is a legal move
 */
BOOLEAN legal_move(l_move Z)
{
    int i;

    for (i = 0; i < game.ZL.nr_moves; i++) {
	if ((game.ZL.moves[i].column == Z.column) && (game.ZL.moves[i].row == Z.row) &&
	    (game.ZL.moves[i].dest_col == Z.dest_col) &&
	    (game.ZL.moves[i].dest_row == Z.dest_row))
	    return TRUE;
    }
    return FALSE;
}


/*
   Make the best move
 */
void make_move(l_move z)
{
    /*  update_fields(c_color, game.best_moves[0][0]); */
    update_fields(c_color, z);
    (game.move_no)++;
    memcpy(game.history[game.move_no], game.current_board, BOARD_SIZE);
}

void get_best_move(l_move * Z)
{
    Z->row = game.best_moves[0][0].row;
    Z->column = game.best_moves[0][0].column;
    Z->dest_row = game.best_moves[0][0].dest_row;
    Z->dest_col = game.best_moves[0][0].dest_col;
    Z->move_value = game.best_moves[0][0].move_value;
}



/*
   Generate movelist.
   ADR - current player (c_color or h_color)
   ZL  - pointer to movelist
   Test - ??
   sort_opt - evaluate the resulting positions and sort the movelist.
 */
void gen_movelist(int ADR, move_list * ZL, BOOLEAN Test, BOOLEAN sort_opt)
{
    int line, Anz, i, j, k, zi, zj;
    board SF;

    if ((game.stk_ptr == 0) && game.movelist_valid && game.comp_move) {
        mvlist = ZL;
        bsort_list(mvlist);
/*        print_mvlist(game.game_stack[0].Zl); */           /* remove this */
        del_vals(&(game.game_stack[game.stk_ptr].Zl));
/*        mvlist->nr_moves = game.marked[0];*/
        game.marked[0] = 0;
        game.marked[1] = 0;
        return;
    }
    curr_color = ADR;
    mvlist = ZL;
    mvlist->nr_moves = 0;
    game.movelist_valid = 1;
    for (i = 0; i < MAXFIELDS; i++) {
        for (j = 0; j < MAXFIELDS; j++) {
            if (game.current_board[j][i] == curr_color) {
                for (line = diag1; line <= senk; line++) {
                    Anz = cnt_stones(j, i, line);
                    zj = j;
                    zi = i;
                    calc_dest(j, i, &zj, &zi, Anz, line);
                    if (is_legal(j, i, zj, zi)) {
                    note_move(j, i, zj, zi);
                    }
                    calc_dest(j, i, &zj, &zi, -Anz, line);
                    if (is_legal(j, i, zj, zi)) {
                    note_move(j, i, zj, zi);
                    }
                }
            }
        }
    }
    if ((mvlist->nr_moves > 1) && sort_opt) {
        memcpy(SF, game.current_board, BOARD_SIZE);	/* save current board */
        for (k = 0; k < mvlist->nr_moves; k++) {
            memcpy(game.current_board, SF, BOARD_SIZE);		/* restore board */
            update_fields(curr_color, mvlist->moves[k]);
            if (curr_color == c_color) {
            mvlist->moves[k].move_value = evaluate2();
            } else {
            mvlist->moves[k].move_value = -evaluate2();
            }
        }
        memcpy(game.current_board, SF, BOARD_SIZE);
        sort_list(mvlist);
        if (game.stk_ptr == 0) {
            del_vals(&(game.game_stack[game.stk_ptr].Zl));
        }
    }
}


void update_fields(int Dran, l_move new_move)
{
    game.current_board[new_move.column][new_move.row] = EMPTY;
    game.current_board[new_move.dest_col][new_move.dest_row] = Dran;
}

static void new_value(l_move Z, move_list * L)
{
    int i;

    for (i = 0; i < L->nr_moves; i++) {
	if ((L->moves[i].row == Z.row) && (L->moves[i].column == Z.column)
	    && (L->moves[i].dest_row == Z.dest_row) && (L->moves[i].dest_col == Z.dest_col)) {
	    L->moves[i].move_value = Z.move_value;
	}
    }
}


int count_stones(int color)
{
    int i, j, sum;

    sum = 0;
    for (i = 0; i < MAXFIELDS; i++) {
	for (j = 0; j < MAXFIELDS; j++) {
	    if (game.current_board[i][j] == color) {
		sum++;
	    }
	}
    }
    return sum;
}


int central_pos(void)
{
    int s, w, i, j;

    s = 0;
    w = 0;
    for (i = 2; i < 6; i++) {
	for (j = 2; j < 6; j++) {
	    if (game.current_board[j][i] != EMPTY) {
		if (game.current_board[j][i] == c_color) {
		    if ((i > 2) && (i < 5) && (j > 2) && (j < 5)) {
			w = w + 4;
		    } else {
			w = w + 2;
		    }
		} else {
		    if ((i > 2) && (i < 5) && (j > 2) && (j < 5)) {
			s = s + 4;
		    } else {
			s = s + 2;
		    }
		}
	    }
	}
    }
    return (w - s);
}



/*
   calc_dest: calculate the destination for a move with the given parameters
   s: source column, z: source row, dist: distance, direct: direction.
 */

static void calc_dest(int s, int z, int *zs, int *zz, int dist, int direct)
{
    if (direct == diag1) {
	*zz = z + dist;
	*zs = s + dist;
    } else if (direct == diag2) {
	*zz = z - dist;
	*zs = s + dist;
    } else if (direct == waag) {
	*zs = s + dist;
    } else if (direct == senk) {
	*zz = z + dist;
    }
}



/*
   is_legal: return whether or not a move from column s and row z to column zs
   and row zz is valid.
 */

static BOOLEAN is_legal(int s, int z, int zs, int zz)
{
    int laufz, laufs;

    if ((zs < 0) || (zs > MAX_COLS) || (zz < 0) || (zz > MAX_ROWS))
	return FALSE;
    laufz = z;
    laufs = s;
    while (zz > laufz) {
	laufz++;
	if (zs > laufs) {
	    laufs++;
	} else if (zs < laufs) {
	    laufs--;
	}
	if (game.current_board[laufs][laufz] == game.opponent[curr_color]) {
	    return ((laufz == zz) && (laufs == zs));
	}
    }
    while (zz < laufz) {
	laufz--;
	if (zs > laufs) {
	    laufs++;
	} else if (zs < laufs) {
	    laufs--;
	}
	if (game.current_board[laufs][laufz] == game.opponent[curr_color]) {
	    return ((laufz == zz) && (laufs == zs));
	}
    }
    if (z == zz) {
	while (zs > laufs) {
	    laufs++;
	    if (game.current_board[laufs][laufz] == game.opponent[curr_color]) {
		return (laufs == zs);
	    }
	}
	while (zs < laufs) {
	    laufs--;
	    if (game.current_board[laufs][laufz] == game.opponent[curr_color]) {
		return (laufs == zs);
	    }
	}
    }
    return (game.current_board[zs][zz] != curr_color);
}


/*
   cnt_stones: Count the stones on a given line.
 */

static int cnt_stones(int s, int z, int direct)
{
    int anz = 0;

    switch (direct) {
    case diag1:
	if (s >= z) {
	    s = s - z;
	    z = 0;
	} else {
	    z = z - s;
	    s = 0;
	}
	do {
	    if (game.current_board[s][z] != EMPTY)
		anz++;
	    s++;
	    z++;
	}
	while ((s <= MAX_COLS) && (z <= MAX_ROWS));
	break;
    case diag2:
	while ((z > 0) && (s < MAX_COLS)) {
	    z--;
	    s++;
	}
	do {
	    if (game.current_board[s][z] != EMPTY)
		anz++;
	    z++;
	    s--;
	}
	while ((z <= MAX_ROWS) && (s >= 0));
	break;
    case waag:
	s = 0;
	do {
	    if (game.current_board[s][z] != EMPTY)
		anz++;
	    s++;
	}
	while (s <= MAX_COLS);
	break;
    case senk:
	z = 0;
	do {
	    if (game.current_board[s][z] != EMPTY)
		anz++;
	    z++;
	}
	while (z <= MAX_ROWS);
	break;
    }
    return anz;
}


static void sort_list(move_list * movelist)
{
    int i, j, m, maxi, maxj;
    l_move t;

    maxi = ((movelist->nr_moves) - 1);
    maxj = movelist->nr_moves;
    for (i = 0; i < maxi; i++) {
	m = i;
	for (j = (i + 1); j < maxj; j++) {
	    if (movelist->moves[j].move_value > movelist->moves[m].move_value)
		m = j;
	}
	if (m != i) {
	    t = movelist->moves[i];
	    movelist->moves[i] = movelist->moves[m];
	    movelist->moves[m] = t;
	}
    }
}

/* bubble sort is only used when stk_ptr = 0, because it keeps
   the order of previous sortings. */
static void bsort_list(move_list * movelist)
{
    int i, j, n;
    l_move t;
    n = (movelist->nr_moves - 1);
    for (i =  n; i >= 1; i--) {
        for (j = 1; j <= i; j++) {
            if (movelist->moves[j].move_value > movelist->moves[j-1].move_value) {
                t = movelist->moves[j];
                movelist->moves[j] = movelist->moves[j-1];
                movelist->moves[j-1] = t;
            }
        }
    }
}

/*
    del_vals: Make the values of all the moves in the list invalid.
    This should be done after sorting and is needed for iterative
    deepening.
*/
static void del_vals(move_list * movelist)
{
    int i, maxi;

    maxi = (movelist->nr_moves);
    for (i = 0; i < maxi; i++) {
        movelist->moves[i].move_value = LOA_NOVAL;
    }
}

static void note_move(int s, int z, int zs, int zz)
{
    mvlist->moves[mvlist->nr_moves].column = s;
    mvlist->moves[mvlist->nr_moves].row = z;
    mvlist->moves[mvlist->nr_moves].dest_col = zs;
    mvlist->moves[mvlist->nr_moves].dest_row = zz;
    mvlist->nr_moves++;
}



/*
   take_back_stack: take back the last move from the game stack.
 */

void take_back_stack(void)
{
    game.stk_ptr--;
    memcpy(game.current_board, game.game_stack[game.stk_ptr].the_board, BOARD_SIZE);
}


void mark_move(int W)
{
    int i;

    game.game_stack[game.stk_ptr].last_move.move_value = W;
    game.best_moves[game.stk_ptr][0] = game.game_stack[game.stk_ptr].last_move;
    game.best_moves[game.stk_ptr][0].move_value = W;
    if (game.stk_ptr == 0) {
	    new_value(game.game_stack[game.stk_ptr].last_move,
		  &(game.game_stack[game.stk_ptr].Zl));
    }
    for (i = 0; i < (game.marked[game.stk_ptr] + 1); i++) {
	    game.best_moves[game.stk_ptr][i + 1] = game.best_moves[game.stk_ptr + 1][i];
    }
/*    game.marked[game.stk_ptr] = 1 + game.marked[game.stk_ptr + 1];*/
    game.marked[game.stk_ptr]++;
}


/*
   comps_turn: return if it's computer's turn.
 */

BOOLEAN comps_turn(void)
{
    gen_movelist(game.game_stack[game.stk_ptr].to_move,
		 &(game.game_stack[game.stk_ptr].Zl), FALSE,
		 (game.stk_ptr < (game.depth - 1)));
    if (game.game_stack[game.stk_ptr].Zl.nr_moves == 0) {
	game.game_stack[game.stk_ptr].to_move =
	    game.opponent[game.game_stack[game.stk_ptr].to_move];
	gen_movelist(game.game_stack[game.stk_ptr].to_move,
		     &(game.game_stack[game.stk_ptr].Zl), FALSE,
		     (game.stk_ptr < game.depth));
    }
    game.game_stack[game.stk_ptr].first_move = TRUE;
/*
    if (game.stk_ptr == 0) {
        del_vals(&(game.game_stack[game.stk_ptr].Zl));
    }
*/
    return (game.game_stack[game.stk_ptr].to_move == c_color);
}


/*
   computer_move: let the computer make its move.
 */

void computer_move(void)
{
    extern int calcmode;
    int W, i, old_progress, last_depth;

    init_game_stack();
    W = 0;
    last_depth = 0;
    game.comp_move = 1;
    if (calcmode == 0) {
        if (game.depth > 4) {
            /* calculate silently on a lower level */
            old_progress = progress;
            progress = 0;
            for (i = 3; (i < game.level) && ( W < MAXPOINTS ); i+=2) {
                W = min_max( i , comps_turn, next_move, take_back_stack,
                    mark_move, evaluate2);
                last_depth = i;
            }
            if (W < MAXPOINTS) {
                /* if no winning move found, calculate on original depth */
                progress = old_progress;
                W = min_max(game.depth , comps_turn, next_move, take_back_stack,
		            mark_move, evaluate2);
            } else {
                /* winning move found, calc again, just to show xloa the progress */
                progress = old_progress;
                W = min_max(last_depth , comps_turn, next_move, take_back_stack,
		            mark_move, evaluate2);
            }
        } else {
            W = min_max(game.depth , comps_turn, next_move, take_back_stack,
		        mark_move, evaluate2);
        }
    } else {
        W = min_max(game.depth -1 , comps_turn, next_move, take_back_stack,
		    mark_move, evaluate2);
/*        print_mvlist(game.game_stack[0].Zl);*/
      if (game.game_stack[0].Zl.nr_moves > 1) {
/*            del_vals(&(game.game_stack[game.stk_ptr].Zl)); */
                W = min_max(game.depth, comps_turn, next_move, take_back_stack,
		        mark_move, evaluate2);
/*          print_mvlist(game.game_stack[0].Zl);*/
        }
        if (game.game_stack[0].Zl.nr_moves > 1) {
/*            del_vals(&(game.game_stack[game.stk_ptr].Zl)); */
            W = min_max(game.depth +1, comps_turn, next_move, take_back_stack,
		        mark_move, evaluate2);
/*            print_mvlist(game.game_stack[0].Zl);*/
        }
    }
    game.stk_ptr = 0;
    game.movelist_valid = 0;
    game.comp_move = 0;
    memcpy(game.current_board, game.game_stack[game.stk_ptr].the_board, BOARD_SIZE);
}


/*
   take_back: take back the last move.
 */

void take_back(void)
{
    game.move_no--;
    memcpy(game.current_board, game.history[game.move_no], BOARD_SIZE);
    game.whose_turn = game.opponent[game.whose_turn];
}

static int power(int base, int n)
{
    int p;

    for (p = 1; n > 0; --n)
	p = p * base;
    return p;
}
