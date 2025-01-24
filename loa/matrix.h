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

   RCS: $Id: matrix.h,v 1.8 2001/12/24 19:02:10 christian Exp christian $

 */


     /* matrix.h - calculate several important things that are needed to evaluate a position */

#ifndef MATRIX_H
#define MATRIX_H

typedef struct {
    int num_stones;		/* number of stones */
    int num_groups;		/* number of groups */
    int zero_dist;		/* numver of zero-distances */
    int group_value;		/* a value for the sizes of and the distances between the groups */
    BOOLEAN DEK;		/* indicator for a (more or less) "dangerous" situation */
    int mst;			/* minimal spanning tree  - not used */
    int sumdist;		/* sum of distances between all stones */
} matrix_value;

int get_matrix_value(int F, matrix_value * result);

int group_distance(int F);

void gen_ini_matrix(void);

#endif
