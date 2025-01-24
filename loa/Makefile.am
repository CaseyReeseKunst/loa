bin_PROGRAMS = loa
bin_SCRIPTS = tkloa
CLEANFILES = $(bin_SCRIPTS)

EXTRA_DIST = tkloa.tcl.in rules.txt commands.txt

loalibdir = $(libdir)/loa
loalib_DATA = rules.txt commands.txt

loa_SOURCES = game.c loa.c gamebase.c matrix.c olib.c back.c loa.h gamebase.h matrix.h olib.h back.h modula.h

tkloa: $(srcdir)/tkloa.tcl.in
	rm -f tkloa
	echo "#! " $(WISH)  > tkloa
	cat $(srcdir)/tkloa.tcl.in >> tkloa
	chmod ugo+x tkloa
