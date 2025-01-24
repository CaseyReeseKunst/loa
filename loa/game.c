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

   RCS: $Id: game.c,v 1.40.1.1 2002/01/10 22:15:14 christian Exp christian $
 */

#include <stdio.h>
#include <string.h>
#include "loa.h"
#include "modula.h"
#include "back.h"
#include <stdlib.h>
#include "olib.h"
#include <time.h>

#define MAXLEN 128
#define MAXKEYS 31

char *keywords[MAXKEYS] = { "move", "quit", "say", "play", "level", "show",
    "showwhite", "showblack", "cc", "from", "takeback", "setgw", "who",
    "defend",
    "layout", "groupcount", "movelist", "preview", "progress", "hint",
    "use_rand",
    "connections", "central", "clearboard", "setstone", "mst", "sumdist",
    "stonecount", "checkpos", "help", "calcmode"
};

char *rdline;
char line[MAXLEN];
game_struct game;		/* everything happens here :-) */
game_struct init_struct;
int h_color = BLACK;
int c_color = WHITE;
int gw = 2;			/* weight of the distances between the groups */
int dist0 = 2;			/* weight of zero distance */
int mf = 5;			/* weight of central positions */
int defend = 0;
int mst = 0;			/* use minimal spanning tree */
int sum_dist = 6;		/* weight of sum of distances between all stones */
int use_anzgr = 9;		/* weight of number of groups */
int use_numstones = 5;		/* use number of stones */
int use_movelist, use_preview;
BOOLEAN use_rand = FALSE;
BOOLEAN progress = FALSE;
BOOLEAN hint_available = FALSE;
BOOLEAN agressor = FALSE;
int akt_wert = 0;
int collide_counter, tr_counter, store_counter;
int test_upper, test_lower;
int layout = 0;			/* 1 means scrambled */
int calcmode = 0;		/* 0=normal, 1=iterative deepening


				   int IO_loop(void);

				   /*int NextToc(void);
				   int DoTest(void); */
int mmove(void);

int play(void);			/* let loa make it's move */
int set_level(void);
int showboard(void);
void show_value(void);		/* show the value of the current position */
int showcolor(int);
int show_target_positions(void);
int setgw(void);
int setmst(void);		/* calculate minimal spanning tree */
int set_calcmode(void);		/* normal(0) or iterative deepening(1) */
int set_defend(void);
int set_layout(void);
int set_progress(void);
int set_rand(void);
void give_hint(void);
void pre_eval(void);		/* check some special conditions */
int set_stone(void);
int sumstones(void);
void show_help(void);


/* let loa make it's move */

int play(void)
{
    char ms[6];
    l_move Z;

    if (game.move_no == MAXMOVES - 1) {
	printf("error: maximal number of moves reached !\n");
	fflush(stdout);
	return 1;
    }
    if (abs(evaluate2()) >= MAXPOINTS) {
	printf("error: game already over\n");
	fflush(stdout);
	return 1;
    }
    hint_available = TRUE;
    if (layout == 0) {
	if (get_move(&Z)) {	/* check opening library */
	    gen_movelist(c_color, &(game.ZL), FALSE, TRUE);
	    if (legal_move(Z)) {
		hint_available = FALSE;
		if (progress) {
		    printf("calculated: 0 of 1\n");	/* xloa needs this for
							   the progress-bar */
		    fflush(stdout);
		}
	    } else {
		computer_move();	/* calculate next move */
		get_best_move(&Z);
	    }
	} else {
	    computer_move();
	    get_best_move(&Z);
	}
    } else {
	computer_move();
	get_best_move(&Z);
    }
    check_move(Z);		/* Update olib */
    game.whose_turn = game.opponent[game.whose_turn];	/* now it's the opponent's turn */
    make_move(Z);
    ms[0] = Z.column + 'a';
    ms[1] = Z.row + '1';
    ms[2] = ' ';
    ms[3] = Z.dest_col + 'a';
    ms[4] = Z.dest_row + '1';
    ms[5] = '\0';
    printf("%s%s%s", "mymove: ", ms, "\n");
    fflush(stdout);
    show_value();
    if (abs(evaluate1()) >= MAXPOINTS) {
	printf("game over !  \n");
	fflush(stdout);
    }
    return 1;
}

int show_target_positions(void)
{
    char targets[25], *from;
    int i, j;

    if ((from = strtok(NULL, " ")) != NULL) {
	gen_movelist(game.whose_turn, &(game.ZL), FALSE, TRUE);
	j = 0;
	for (i = 0; i < game.ZL.nr_moves; i++) {
	    if (game.ZL.moves[i].column + 'a' == from[0] &&
		game.ZL.moves[i].row + '1' == from[1]) {
		targets[j] = game.ZL.moves[i].dest_col + 'a';
		j++;
		targets[j] = game.ZL.moves[i].dest_row + '1';
		j++;
		targets[j] = ' ';
		j++;
	    }
	}
	targets[j] = '\0';
	printf("%s%s%s", "to: ", targets, "\n");
	fflush(stdout);
    }
    return 1;
}



/* show the positions of the stones with the given color */

int showcolor(int color)
{
    int i, j, c;
    char line[38];

    c = 0;
    for (i = 0; i < MAXFIELDS; i++) {
	for (j = 0; j < MAXFIELDS; j++) {
	    if (game.current_board[i][j] == color) {
		line[c] = i + 'a';
		c++;
		line[c] = j + '1';
		c++;
		line[c] = ' ';
		c++;
	    }
	}
    }
    line[c] = '\0';
    printf("%s%s", line, "\n");
    fflush(stdout);
    return 1;
}

int set_layout(void)
{
    extern int layout;
    char *clayout;

    if ((clayout = strtok(NULL, " ")) != NULL) {
	layout = clayout[0] - '0';
	if ((layout < 0) || (layout > 1)) {
	    printf("%s\n", "error: layout out of range [0-1]");
	} else {
	    if (layout == 0) {
		setup_initpos();
		memcpy(game.history[game.move_no], game.current_board,
		       BOARD_SIZE);
	    } else {
		scrambled();
		memcpy(game.history[game.move_no], game.current_board,
		       BOARD_SIZE);
	    }
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int set_progress(void)
{
    int on_off;
    char *con_off;

    if ((con_off = strtok(NULL, " ")) != NULL) {
	on_off = con_off[0] - '0';
	if ((on_off < 0) || (on_off > 1)) {
	    printf("%s\n", "error: progress out of range [0-1]");
	} else {
	    progress = on_off;
	    printf("ok\n");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int set_rand(void)
{
    int on_off;
    char *con_off;

    if ((con_off = strtok(NULL, " ")) != NULL) {
	on_off = con_off[0] - '0';
	if ((on_off < 0) || (on_off > 1)) {
	    printf("%s\n", "error: use_rand out of range [0-1]");
	} else {
	    use_rand = on_off;
	    printf("ok\n");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}


int setgw(void)
{
    int newgw;
    char *snewgw;

    if ((snewgw = strtok(NULL, " ")) != NULL) {
	newgw = snewgw[0] - '0';
	if ((newgw < 0) || (newgw > 9)) {
	    printf("%s\n", "error: gw out of range [0-9]");
	} else {
	    gw = newgw;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int sumdist(void)
{
    int newval;
    char *snewval;

    if ((snewval = strtok(NULL, " ")) != NULL) {
	newval = snewval[0] - '0';
	if ((newval < 0) || (newval > 9)) {
	    printf("%s\n", "error: sumdist out of range [0-9]");
	} else {
	    sum_dist = newval;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int setconnections(void)
{
    int newcon;
    char *snewcon;

    if ((snewcon = strtok(NULL, " ")) != NULL) {
	newcon = snewcon[0] - '0';
	if ((newcon < 0) || (newcon > 9)) {
	    printf("%s\n", "error: con out of range [0-9]");
	} else {
	    dist0 = newcon;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int setcentral(void)
{
    int newcentral;
    char *snewcentral;

    if ((snewcentral = strtok(NULL, " ")) != NULL) {
	newcentral = snewcentral[0] - '0';
	if ((newcentral < 0) || (newcentral > 9)) {
	    printf("%s\n", "error: central out of range [0-9]");
	} else {
	    mf = newcentral;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}


int set_defend(void)
{
    char *sdefend;
    int newdefend;

    if ((sdefend = strtok(NULL, " ")) != NULL) {
	newdefend = sdefend[0] - '0';
	if (newdefend < 0) {
	    printf("%s\n", "error: out of range [0-4]");
	} else {
	    defend = newdefend;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token");
    }
    fflush(stdout);
    return 1;
}

int set_anzgr(void)
{
    char *sanzgr;
    int newanzgr;

    if ((sanzgr = strtok(NULL, " ")) != NULL) {
	newanzgr = sanzgr[0] - '0';
	if (newanzgr < 0) {
	    printf("%s\n", "error: out of range [0-9]");
	} else {
	    use_anzgr = newanzgr;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token");
    }
    fflush(stdout);
    return 1;
}


int sumstones(void)
{
    char *sumst;
    int newsumst;
    extern int use_numstones;

    if ((sumst = strtok(NULL, " ")) != NULL) {
	newsumst = sumst[0] - '0';
	if (newsumst < 0) {
	    printf("%s\n", "error: out of range [0-9]");
	} else {
	    use_numstones = newsumst;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token");
    }
    fflush(stdout);
    return 1;
}

int set_preview(void)
{
    char *spreview;
    int newpreview;

    if ((spreview = strtok(NULL, " ")) != NULL) {
	newpreview = spreview[0] - '0';
	if (newpreview < 0) {
	    printf("%s\n", "error: out of range [0-1]");
	} else {
	    use_preview = newpreview;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token");
    }
    fflush(stdout);
    return 1;
}

int setmst(void)
{
    int newmst;
    char *snewmst;

    if ((snewmst = strtok(NULL, " ")) != NULL) {
	newmst = snewmst[0] - '0';
	if ((newmst < 0) || (newmst > 9)) {
	    printf("%s\n", "error: mst out of range [0-9]");
	} else {
	    mst = newmst;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int set_calcmode(void)
{
    int newmode;
    char *snewmode;

    if ((snewmode = strtok(NULL, " ")) != NULL) {
	newmode = snewmode[0] - '0';
	if ((newmode < 0) || (newmode > 1)) {
	    printf("%s\n", "error: calcmode out of range [0-1]");
	} else {
	    calcmode = newmode;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token!");
    }
    fflush(stdout);
    return 1;
}

int set_movelist(void)
{
    char *smovelist;
    int newmovelist;

    if ((smovelist = strtok(NULL, " ")) != NULL) {
	newmovelist = smovelist[0] - '0';
	if (newmovelist < 0) {
	    printf("%s\n", "error: out of range [0-1]");
	} else {
	    use_movelist = newmovelist;
	    printf("%s\n", "ok");
	}
    } else {
	printf("%s\n", "error: missing token");
    }
    fflush(stdout);
    return 1;
}


int mmove(void)
{
    char *from, *to;
    l_move Z;

    if (game.move_no == MAXMOVES - 1) {
	printf("error: maximal number of moves reached !\n");
	fflush(stdout);
	return 1;
    }
    if ((from = strtok(NULL, " ")) != NULL) {
	if ((to = strtok(NULL, " ")) != NULL) {
	    if (abs(evaluate2()) >= MAXPOINTS) {
		printf("error: game already over\n");
		fflush(stdout);
		return 1;
	    }
	    gen_movelist(h_color, &(game.ZL), FALSE, TRUE);
	    Z.column = from[0] - 'a';
	    Z.row = from[1] - '1';
	    Z.dest_col = to[0] - 'a';
	    Z.dest_row = to[1] - '1';
	    if (legal_move(Z)) {
		update_fields(h_color, Z);
		(game.move_no)++;
		check_move(Z);
		memcpy(game.history[game.move_no], game.current_board,
		       BOARD_SIZE);
		game.whose_turn = game.opponent[game.whose_turn];
		show_value();
		hint_available = FALSE;
		printf("ok\n");
		fflush(stdout);
	    } else {
		printf("error: move illegal \n");
		fflush(stdout);
	    }
	} else {
	    printf("error: missing token3 \n");
	    fflush(stdout);
	}
    } else {
	printf("error: missing token2 \n");
	fflush(stdout);
    }
    return 1;
}

int set_level(void)
{
    int l;
    char *tok;

    if ((tok = strtok(NULL, " ")) != NULL) {
	l = tok[0] - '0';
	if (l > 1 && l < 10) {
	    game.depth = l;
	    game.level = l;
	    printf("ok\n");
	    fflush(stdout);
	} else {
	    printf("error: level illegal \n");
	    fflush(stdout);
	}
    } else {
	printf("error: missing value \n");
	fflush(stdout);
    }
    return 1;
}


int showboard(void)
{
    int i, j;
    char outs[18] = "                 ";

    for (i = 7; i >= 0; i--) {
	outs[0] = '8' - (7 - i);
	outs[17] = '\0';
	for (j = 0; j < 8; j++) {
	    if (game.current_board[j][i] == WHITE) {
		outs[2 * (j + 1)] = 'w';
	    } else if (game.current_board[j][i] == BLACK) {
		outs[2 * (j + 1)] = 'b';
	    } else {
		outs[2 * (j + 1)] = '.';
	    }
	}
	printf("%s%s", outs, "\n");
	fflush(stdout);
	/*    printf("-+-+-+-+-+-+-+-+-+\n"); */
    }
    printf("  A B C D E F G H\n");
    fflush(stdout);
    return 1;
}

void give_hint(void)
{
    char hint[8];

    hint[1] = game.best_moves[0][1].row + '1';
    hint[0] = game.best_moves[0][1].column + 'A';
    hint[6] = game.best_moves[0][1].dest_row + '1';
    hint[5] = game.best_moves[0][1].dest_col + 'A';
    hint[2] = ' ';
    hint[3] = '-';
    hint[4] = ' ';
    hint[7] = '\0';
    printf("%s\n", hint);
    fflush(stdout);
}

void pre_eval(void)
{				/* check some special conditions */
    if (game.move_no < 3) {
	if (count_stones(c_color) < count_stones(h_color)) {
	    agressor = TRUE;
	    mf = -abs(mf);
	}
    } else if (game.move_no == 10) {
	mf = abs(mf);
    }
}

int set_stone(void)
{
    char *position, *color;
    int x, y, nret;

    nret = TRUE;
    if ((position = strtok(NULL, " ")) != NULL) {
	if ((color = strtok(NULL, " ")) != NULL) {
	    x = position[0] - 'a';
	    y = position[1] - '1';
	    if ((x < 0) || (y < 0) || (x > MAX_ROWS) || (y > MAX_COLS)) {
		printf("error: illegal position! \n");
		nret = FALSE;
	    } else {
		if (strcmp(color, "black") == 0) {
		    if (count_stones(BLACK) < 12) {
			game.current_board[x][y] = BLACK;
		    } else {
			printf("error: too many black stones! \n");
			nret = FALSE;
		    }
		} else if (strcmp(color, "white") == 0) {
		    if (count_stones(WHITE) < 12) {
			game.current_board[x][y] = WHITE;
		    } else {
			printf("error: too many white stones! \n");
			nret = FALSE;
		    }
		} else if (strcmp(color, "empty") == 0) {
		    game.current_board[x][y] = EMPTY;
		} else {
		    printf("error: unknown color!\n");
		    nret = FALSE;
		}
	    }
	} else {
	    printf("error: missing token!\n");
	    nret = FALSE;
	}
    } else {
	printf("error: missing token!\n");
	nret = FALSE;
    }
    if (nret)
	printf("ok\n");
    fflush(stdout);
    if (nret)
	hint_available = FALSE;
    return nret;
}

int IO_loop(void)
{
    int nkey, i, nret;
    char *toc;

    nkey = MAXKEYS;
    rdline = fgets(line, MAXLEN, stdin);
    if (rdline != NULL) {
	rdline[strlen(rdline) - 1] = '\0';
	if ((toc = strtok(rdline, " ")) != NULL) {
	    for (i = 0; i < MAXKEYS; i++) {
		if (strcmp(keywords[i], toc) == 0) {
		    nkey = i;
		    break;
		}
	    }
	}
    }
    switch (nkey) {
    case 0:
	if (game.whose_turn == h_color) {
	    nret = mmove();
	} else {
	    printf("error: not your turn !\n");
	    fflush(stdout);
	    return 1;
	}
	break;
    case 1:
	printf("quit\n");
	fflush(stdout);
	return 0;
    case 2:
	break;
    case 3:
	if (game.whose_turn == c_color) {
	    nret = play();
	} else {
	    printf("error: your turn !\n");
	    fflush(stdout);
	    return 1;
	}
	break;
    case 4:
	nret = set_level();
	break;
    case 5:
	nret = showboard();
	break;
    case 6:
	nret = showcolor(WHITE);
	break;
    case 7:
	nret = showcolor(BLACK);
	break;
    case 8:
	swap_colors();
	akt_wert = -akt_wert;
	printf("ok\n");
	fflush(stdout);
	break;
    case 9:
	show_target_positions();
	break;
    case 10:
	if (game.move_no > 0) {
	    take_back();
	    hint_available = FALSE;
	    printf("ok\n");
	} else {
	    printf("error: first move!\n");
	}
	fflush(stdout);
	break;
    case 11:
	setgw();
	break;
    case 12:
	if (game.whose_turn == WHITE) {
	    printf("%s\n", "who: w");
	} else {
	    printf("%s\n", "who: b");
	}
	fflush(stdout);
	break;
    case 13:
	set_defend();
	break;
    case 14:
	if (game.move_no > 0) {
	    printf("error: at least one move made!\n");
	    fflush(stdout);
	} else {
	    set_layout();
	}
	break;
    case 15:
	set_anzgr();
	break;
    case 16:
	set_movelist();
	break;
    case 17:
	set_preview();
	break;
    case 18:
	set_progress();
	break;
    case 19:
	if ((game.move_no > 1) && hint_available) {
	    give_hint();
	} else {
	    printf("error: no hint available\n");
	    fflush(stdout);
	}
	break;
    case 20:
	set_rand();
	break;
    case 21:
	setconnections();
	break;
    case 22:
	setcentral();
	break;
    case 23:
	clear_board();
	printf("ok\n");
	fflush(stdout);
	hint_available = FALSE;
	break;
    case 24:
	set_stone();
	hint_available = FALSE;
	/*    game.move_no = 0; */
	break;
    case 25:
	setmst();
	break;
    case 26:
	sumdist();
	break;
    case 27:
	sumstones();
	break;
    case 28:
	if (abs(evaluate2()) >= MAXPOINTS) {
	    printf("final position\n");
	} else {
	    printf("ok\n");
	}
	fflush(stdout);
	break;
    case 29:
	show_help();
	break;
    case 30:
	set_calcmode();
	break;
    default:
	printf("error: type 'quit' to quit\n");
	fflush(stdout);
	return 1;
    }
    return 1;
}

void show_value(void)
{
    int W, M;
    char iwin[] = " -- I win !";
    char youwin[] = " -- you win !";
    char *winner = "";

    W = evaluate2();
    akt_wert = W;
    M = central_pos();
    if (W == MAXPOINTS) {
	winner = iwin;
    }
    if (W == -MAXPOINTS) {
	winner = youwin;
    }
    if (game.best_moves[0][0].move_value == -5000) {
	printf("%s%d%s%s", "Value: ", W, winner, " -- offer to give up\n");
    } else {
	printf("%s%d%s%s", "Value: ", W, winner, "\n");
    }
    /*    printf("%s%d%s", "Mittelfeld: ", M, "\n"); */
    fflush(stdout);
}

void show_help(void)
{
    printf("loa knows the following commands:\n\n");
    printf("help         - shows this page\n");
    printf
	("move from to - use this to make your move (e.g. 'move b1 b3')\n");
    printf("quit	     - quit the game\n");
    printf("play	     - let loa make its move\n");
    printf("level [2-9]  - set the search depth to 2-9 (Half)moves\n");
    printf("show	     - shows the current board\n");
    printf
	("showwhite    - prints a list with the positions of the white stones\n");
    printf
	("showblack    - prints a list with the positions of the black stones\n");
    printf("cc	     - exchange the colors between you and loa\n");
    printf
	("from field   - 'from c1', shows all legal moves you can make with the stone on c1\n");
    printf("takeback     - undo the last (half) move\n");
    printf
	("who	     - prints the color of the player that has to make the next move\n");
    printf
	("progess 0|1  - type 'progress 1' if you want to see the progress of loa's calculations\n");
    printf
	("hint	     - show what loa assumes to be the best possible move for you\n");
    printf("clearboard   - remove all stones from the board\n");
    printf
	("setstone field color - 'setstone g4 black', places a black stone on field g4\n");
    printf
	("layout 0|1   - 0 means the standard layout, 1 means 'scamled'\n");
    fflush(stdout);
}


int main(int argc, char *argv[])
{
    time_t curr_time;

/*    int c;
    while (1)
    {
	int option_index = 0;
	static struct option long_options[] =
	{
	    {"help",0,0,'h'},
	    {"version",0,0,'v'}
	};
	c = getopt_long(argc, argv, "hv", long_options, &option_index);
	if (c == -1)
	    break;
	switch (c)
	{
	    case 'h':
		printf("start loa without any options.\n");
		printf("report bugs to: cweninger@gillion.de\n");
	        return 0;
	    case 'v':
		printf("loa version 1.0\n");
		printf("Copyright (C) 2001 Christian Weninger\n");
		printf("loa comes with NO WARRANTY,\n");
		printf("to the extent permitted by law.\n");
		printf("You may redistribute copies of loa\n");
		printf("under the terms of the GNU General Public License.\n");
		printf("For more information about these matters,\n");
		printf("see the files named COPYING.\n");
		return 0;
	}
    }*/
    /*    printf("\n\n\n"); */
    printf("(L)ines (O)f (A)ction \n");
    printf("Version 1.0\n");
    printf("Copyright (C) 2001 by Christian Weninger\n");
    /*    printf("LOA comes with ABSOLUTELY NO WARRANTY.\n");
       printf("This is free software, and you are welcome to redistribute\n");
       printf("it under certain conditions; read the license for more details\n"); */
    printf
	("Please send bug reports to cweninger@gillion.de (Christian Weninger)\n");
    printf("Type 'help' for a command overview - have fun !\n");
    fflush(stdout);
    curr_time = time(&curr_time);
    srand((unsigned) curr_time);
    ini_struct();
    use_movelist = 0;
    use_preview = 0;
    game = init_struct;
    game.beginner = h_color;
    setup_initpos();
    game.whose_turn = game.beginner;
    game.move_no = 0;
    memcpy(game.history[game.move_no], game.current_board, BOARD_SIZE);
    game.First = TRUE;
    init_game_stack();
    init_lib();
    while (IO_loop()) {;
    }
    return 0;
}
