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

   RCS: $Id: matrix.c,v 1.19 2001/12/24 19:00:25 christian Exp christian $
 */

#include "modula.h"
#include "gamebase.h"
#include "matrix.h"
#include <stdlib.h>

#define max(A, B) ((A) > (B) ? (A) : (B))
#define min(A, B) ((A) < (B) ? (A) : (B))
#define MSIZE (13 * 13 * sizeof(int))

typedef struct {
    int x, y;
} posi;				/* a position */

typedef struct {
    int group_size, group_row;
} gruppe;			/* a group with size and row (in the matrix) */


static int M[13][13];		/* Matrix with distaces between stones or groups */
static int MNULL[13][13];       /* We use this matrix for initialisation */
static int M2 [13][13];         /* corr_matrix should work on a copy of M (perfomance)*/
static posi SF[13];		/* The positions of the stones */
static int stone_counter;	/* Counter for the stones */
static gruppe groups[13];	/* The groups */
static int num_groups, group_total;
static BITSET to_leave;
static int DF[6];		/* counter of distances */
static int sum_dist;		/* sum of distances between all stones */

static void find_zero_rows(void);
static void shrink(void);
static BOOLEAN new_group(int group_row);
static void find_groups(void);
static int Dist(posi p1, posi p2);
static void collect_stones(int Farbe);
static void gen_matrix(void);
static void corr_entry(int row, int column);
static void corr_matrix(void);
static int get_group_value(void);
static void init_matrix(void);
static int DasEndeKommt(void);


/*
   Find rows that contain a zero
 */
static void find_zero_rows(void)
{
    int i, j;

    to_leave = 0;
    for (i = 2; i <= stone_counter; i++) {
	for (j = 1; j <= i - 1; j++) {
	    if (M[i][j] == 0) {
		INCL(to_leave, i);
	    }
	}
    }
}


static void shrink(void)
{
    int ri, rj, wi, wj;

    ri = 2, wi = 2;
    while (ri <= stone_counter) {
	if (!IN(to_leave, ri)) {
	    wj = 1;
	    for (rj = 1; rj <= (ri - 1); rj++) {
		if (!IN(to_leave, rj)) {
		    M[wi][wj] = M[ri][rj];
		    wj++;
		}
	    }
	    wi++;
	}
	ri++;
    }
}

static BOOLEAN new_group(int group_row)
{
    int x;

    for (x = 1; x <= num_groups; x++) {
	if (M[group_row][groups[x].group_row] == 0)
	    return FALSE;
    }
    return TRUE;
}

static void find_groups(void)
{
    int i, j;

    num_groups = 1;
    group_total = 1;
    groups[1].group_size = 1;
    groups[1].group_row = 1;
    for (i = 2; i <= stone_counter; i++) {
	if (M[i][1] == 0) {
	    (groups[1].group_size)++;
	    group_total++;
	}
    }
    for (i = 2; i <= stone_counter; i++) {
	if ((group_total < stone_counter) && new_group(i)) {
	    num_groups++;
	    groups[num_groups].group_row = i;
	    groups[num_groups].group_size = 1;
	    group_total++;
	    for (j = 1; j <= i - 1; j++) {
		if (M[i][j] == 0) {
		    groups[num_groups].group_size++;
		    group_total++;
		}
	    }
	    for (j = i + 1; j <= stone_counter; j++) {
		if (M[j][i] == 0) {
		    groups[num_groups].group_size++;
		    group_total++;
		}
	    }
	}
    }
}


/*
   calculate the distance between two positions
 */
static int Dist(posi p1, posi p2)
{
    int x, y;

    x = abs(p1.x - p2.x);
    y = abs(p1.y - p2.y);
    return (max(x, y) - 1);
}


/*
   Collect the stones of color 'Farbe' into SF[]
 */
static void collect_stones(int Farbe)
{
    int i, j;
    posi Pos;

    stone_counter = 0;
    for (i = 0; i < MAXFIELDS; i++) {
	for (j = 0; j < MAXFIELDS; j++) {
	    if (game.current_board[i][j] == Farbe) {
		stone_counter++;
		Pos.x = j;
		Pos.y = i;
		SF[stone_counter] = Pos;
	    }
	}
    }
}


/*
   Generate the matrix. Afterwards M[x][y] contains the distance
   between stone x and stone y.
 */
static void gen_matrix(void)
{
    int i, j, k;
    extern int sum_dist;

    for (k = 0; k <= 6; k++) {
	DF[k] = 0;
    }
    sum_dist = 0;
    for (i = 2; i <= stone_counter; i++) {
	for (j = 1; j <= i - 1; j++) {
	    M[i][j] = Dist(SF[i], SF[j]);
	    DF[M[i][j]]++;
	    sum_dist = sum_dist + M[i][j];
	}
    }
}

static void corr_entry(int row, int column)
{
    int i, j;

    for (i = 1; i < column; i++) {
	if (M[row][i] < M[column][i]) {
	    M[column][i] = M[row][i];
	    if (M[row][i] == 0) {
		corr_entry(column, i);
	    }
	} else if (M[column][i] < M[row][i]) {
	    M[row][i] = M[column][i];
	    if (M[column][i] == 0) {
		corr_entry(row, i);
	    }
	}
    }
    for (j = row + 1; j <= stone_counter; j++) {
	if (M[j][row] < M[j][column]) {
	    M[j][column] = M[j][row];
	    if (M[j][row] == 0) {
		corr_entry(j, column);
	    }
	} else if (M[j][column] < M[j][row]) {
	    M[j][row] = M[j][column];
	    if (M[j][column] == 0) {
		corr_entry(j, row);
	    }
	}
    }
}


/*
   At this point, M contains the distances between the stones. This
   function converts M into a matrix with the distances between
   the groups.
 */
static void corr_matrix(void)
{
    int row, column;
    memcpy(M2, M, MSIZE);

    for (row = 2; row <= stone_counter; row++) {
	for (column = 1; column < row; column++) {
	    if (M2[row][column] == 0) {
		corr_entry(row, column);
	    }
	}
    }
}


/*
   gw = sum (for each pair of groups: the size of the smaller group * the
   distance between these groups)
 */
static int get_group_value(void)
{
    int gw, i, j;

    gw = 0;
    if (num_groups > 1) {
	for (i = 1; i <= num_groups; i++) {
	    for (j = i + 1; j <= num_groups; j++) {
		gw = gw + min(groups[i].group_size, groups[j].group_size) * M[j][i];
	    }
	}
    }
    return gw;
}



static void init_matrix(void)
{
    memcpy(M, MNULL, MSIZE);
}

void gen_ini_matrix(void)
{
    int i, j;

    for (i = 1; i < 13; i++) {
	for (j = 1; j < 13; j++) {
	    MNULL[i][j] = 0;
	}
    }
}


/* This function is not used anymore, we should remove it */
static int DasEndeKommt(void)
{
    int i, j, gruppe, n, z;
    BOOLEAN res;

    n = 0;
    gruppe = 0;
    if (num_groups < 3) {
	if (M[2][1] > 1) {
	    if ((groups[1].group_size == 1) || (groups[2].group_size == 1)) {
		return 2;
	    } else {
		return 0;
	    }
	} else {
	    return 3;
	}
    }
    for (i = 1; i <= num_groups; i++) {
	z = 0;
	for (j = 1; j < i; j++) {
	    if (M[i][j] > 1) {
		z++;
	    }
	}
	for (j = i + 1; j <= num_groups; j++) {
	    if (M[j][i] > 1) {
		z++;
	    }
	}
	if (z > 1) {
	    n++;
	    gruppe = i;
	}
    }
    if (n > 0) {
	if (n == 1) {
	    res = (groups[gruppe].group_size < 2);
	} else {
	    res = 0;
	}
    } else {
	res = 1;
    }
    return res;
}


int get_matrix_value(int F, matrix_value * result)
{
    init_matrix();
    collect_stones(F);
    gen_matrix();
    corr_matrix();
    find_groups();
    find_zero_rows();
    shrink();
    result->num_stones = stone_counter;
    result->num_groups = num_groups;
    result->zero_dist = DF[0];
    result->group_value = get_group_value();
/*    result->DEK = DasEndeKommt();*/
    result->sumdist = sum_dist;
    return 1;
}



/* If this funktion returns 0 it's interpreted as "game over" - not correct ! */
/* With 53 instaed of 40 it should work */
int group_distance(int F)
{
    init_matrix();
    collect_stones(F);
    gen_matrix();
    corr_matrix();
    find_groups();
    find_zero_rows();
    shrink();
    return (2 * get_group_value() + ((num_groups - 1) * (53 - 2 * DF[0])));
}
