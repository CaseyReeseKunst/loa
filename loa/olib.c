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

   RCS: $Id: olib.c,v 1.7 2001/12/24 19:04:06 christian Exp christian $
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "olib.h"

extern int use_rand;

void insert_sequence(struct mnode *seq);
struct mnode *insert_node(struct mnode *node, struct mnode *list);
struct mnode *search_node(struct mnode *node, struct mnode *list);
struct mnode *make_sequence(const char *mystr);
char *mirror_x(char *dest, const char *source);
char *mirror_y(char *dest, const char *source);

struct mnode *mainlist, *currlist;
char xstr[255];


/* insert_sequence is used to insert a complete sequence of moves
   in the library. seq is a list of moves which are linked with
   the "replys" - pointer. The "next" - pointer must always be NULL. */

void insert_sequence(struct mnode *seq)
{
    extern struct mnode *mainlist;
    struct mnode *currlist;

    currlist = mainlist;
    if (mainlist == NULL) {
	mainlist = seq;
	return;
    } else {
	while (seq != NULL) {
	    currlist = insert_node(seq, currlist);
	    seq = seq->replys;
	}
    }
    return;
}


/* Insert a node in a list and return a pointer to the
   replys. If the node already exists, we return the existing replys.
   If the node is new, we append it to the end of the list and return
   the replys of the new node. */

struct mnode *insert_node(struct mnode *node, struct mnode *list)
{
    struct mnode *tmpnode;

    tmpnode = search_node(node, list);
    if (tmpnode != NULL) {
	if (tmpnode->replys == NULL) {
	    tmpnode->replys = node->replys;
	}
	return tmpnode->replys;	/* node exists, return list of replys */
    } else {
	while (list->next != NULL) {
	    list = list->next;	/* node is new, go to end of list ... */
	}
	list->next = node;	/* ... and insert node. */
	return node->replys;
    }
}


struct mnode *search_node(struct mnode *node, struct mnode *list)
{
    do {
	if (node->move.row == list->move.row &&
	    node->move.column == list->move.column &&
	    node->move.dest_row == list->move.dest_row &&
	    node->move.dest_col == list->move.dest_col) {
	    return list;
	} else {
	    list = list->next;
	}
    } while (list != NULL);
    return list;
}


/* make_sequence makes a list of moves linked by the "replys"-pointer.
   The string is of the form "g1-e3 0 h3-e3 20 g8-f6 0 ...", where
   g1-e3 is the first move and the value 0 means, that this move is
   not recommended. Than he-e3 is the reply to the first move and it
   is a recommended reply which is indicated by the value 20. */

struct mnode *make_sequence(const char *mystr)
{
    char *ts, *tmpstr, *tmpstr_base;
    struct mnode *head, *tail, *node;
    int len;

    head = NULL;
    tail = NULL;
    tmpstr_base = NULL;
    tmpstr = NULL;
    len = strlen(mystr) + 1;
    tmpstr_base = (char *) malloc(len);
    tmpstr = tmpstr_base;
    strcpy(tmpstr, mystr);
    /* get "from" of first move */
    /*  str[strlen(str)-1] = '\0'; */
    ts = strtok(tmpstr, "-");
    do {
	/* make new node */
	node = (struct mnode *) malloc(sizeof(struct mnode));

	node->next = NULL;
	node->replys = NULL;

	/* fill "from"-field of node */
	node->move.column = ts[0] - 'a';
	node->move.row = ts[1] - '1';

	/* get and fill "to"-field of node */
	ts = strtok(NULL, " ");
	node->move.dest_col = ts[0] - 'a';
	node->move.dest_row = ts[1] - '1';

	/* get and fill value of node */
	ts = strtok(NULL, " ");
	node->value = atoi(ts);

	/* get "from"-field of next move */
	ts = strtok(NULL, "-");

	/* append node to list */
	if (head == NULL) {
	    head = node;
	    tail = node;
	} else {
	    tail->replys = node;
	    tail = tail->replys;
	}
    } while (ts != NULL);
    free(tmpstr_base);
    return head;
}


/* If g1-e3 is a good move, then a1-c3 is also a good move. This is done
   by mirror_x. It must always be the hole sequence, which ist mirrored.
 */

char *mirror_x(char *dest, const char *source)
{
    int i;

    dest = strcpy(dest, source);
    for (i = 0; i < strlen(source); i++) {
	if (dest[i] >= 'a' && dest[i] <= 'd') {
	    dest[i] = 'e' + ('d' - dest[i]);
	} else if (dest[i] >= 'e' && dest[i] <= 'h') {
	    dest[i] = 'a' + ('h' - dest[i]);
	}
    }
    return dest;
}


char *mirror_y(char *dest, const char *source)
{
    int i;

    dest = strcpy(dest, source);
    for (i = 0; i < strlen(source); i++) {
	if (dest[i] >= 'a' && dest[i] <= 'h') {
	    i++;		/* there must be a number after a character */
	    if (dest[i] >= '1' && dest[i] <= '4') {
		dest[i] = '5' + ('4' - dest[i]);
	    } else {
		dest[i] = '1' + ('8' - dest[i]);
	    }
	}
    }
    return dest;
}


void new_sequence(const char *mystr)
{
    char *tmpstrX, *tmpstrY, *tmpstrXY;

    tmpstrX = (char *) malloc(strlen(mystr) + 1);
    tmpstrY = (char *) malloc(strlen(mystr) + 1);
    tmpstrXY = (char *) malloc(strlen(mystr) + 1);
    insert_sequence(make_sequence(mystr));
    tmpstrX = mirror_x(tmpstrX, mystr);
    tmpstrY = mirror_y(tmpstrY, mystr);
    tmpstrXY = mirror_y(tmpstrXY, tmpstrX);
    insert_sequence(make_sequence(tmpstrX));
    insert_sequence(make_sequence(tmpstrY));
    insert_sequence(make_sequence(tmpstrXY));
    free(tmpstrX);
    free(tmpstrY);
    free(tmpstrXY);
    return;
}


/* find the best move in the current list */

int get_move(l_move * m)
{
    extern struct mnode *currlist;
    struct mnode *tmplist, *bestmove;
    int bestval, nrfound;

    int rand_nr = 0;		/* test, remove */

    bestval = 0;		/* Don't make moves with value 0 */
    nrfound = 0;
    tmplist = currlist;
    bestmove = NULL;
    while (tmplist != NULL) {
	if ((tmplist->value) > bestval) {
	    bestmove = tmplist;
	    bestval = bestmove->value;
	    nrfound = 1;
	} else if (use_rand && (tmplist->value == bestval) && (bestval > 0)) {
	    rand_nr = rand();
	    if (rand_nr % (nrfound + 1) == 0) {
		bestmove = tmplist;
	    }
	    nrfound++;
	}
	tmplist = tmplist->next;
    }
    if (bestmove == NULL) {
	return 0;
    } else {
	m->row = bestmove->move.row;
	m->column = bestmove->move.column;
	m->dest_row = bestmove->move.dest_row;
	m->dest_col = bestmove->move.dest_col;
	return 1;
    }
    return 0;
}

/* if move m is in the current list, set the current list to
   the list of replys to this move.
 */


void check_move(l_move m)
{
    extern struct mnode *currlist;
    struct mnode *tmplist;

    tmplist = currlist;
    while (tmplist != NULL) {
	if (m.row == tmplist->move.row &&
	    m.column == tmplist->move.column &&
	    m.dest_row == tmplist->move.dest_row &&
	    m.dest_col == tmplist->move.dest_col) {
	    currlist = tmplist->replys;
	    return;
	} else {
	    tmplist = tmplist->next;
	}
    }
    currlist = NULL;
    return;
}

void init_lib(void)
{
    extern struct mnode *mainlist, *currlist;

    new_sequence("c1-c3 20 h3-e3 0 e1-b4 20 ");
    new_sequence("b1-b3 20");
    new_sequence("c1-c3 20 a2-c4 0 e1-b4 20 ");
    new_sequence("c1-c3 20 a5-c7 20 b1-b3 20 a2-c2 20 e1-e3 20 ");
    new_sequence("b8-d6 10 h7-f5 20 f8-c5 20 h6-e6 20 c1-c4 20 h3-d7 20 e1-c3 20 h2-f4 20 ");
    new_sequence("g1-e3 0 h3-e3 20 a5-c5 20 ");
    new_sequence("d1-d3 0 a3-d3 20 e1-e3 0 h3-e3 20");
    new_sequence("d1-d3 0 a3-d3 20 c1-e3 0 h3-e3 20");
    new_sequence("c1-c3 20 h7-h5 0 e1-b4 20");
    new_sequence("g1-e3 0 h3-e3 20 g8-g7 0 h2-f2 20");
    currlist = mainlist;
    return;
}
