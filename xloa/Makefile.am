bin_SCRIPTS = xloa
CLEANFILES = $(bin_SCRIPTS)

EXTRA_DIST = xloa.pl.in Board.pm  CBox.pm  Debug.pm  EStone.pm  Edit.pm \
Help.pm  Init.pm  MBox.pm  MList.pm  Menus.pm  Packer.pm  Save.pm  Stone.pm \
COPYING.txt CUSTOMIZATION.txt examp1.gif examp2.gif examp3.gif examp4.gif \
rules.txt using.txt about.txt title.gif

xloalibdir = $(libdir)/xloa
xloalib_DATA = Board.pm  CBox.pm  Debug.pm  EStone.pm  Edit.pm \
Help.pm  Init.pm  MBox.pm  MList.pm  Menus.pm  Packer.pm  Save.pm  Stone.pm \
COPYING.txt CUSTOMIZATION.txt examp1.gif examp2.gif examp3.gif examp4.gif \
rules.txt using.txt about.txt title.gif

xloa: $(srcdir)/xloa.pl.in
	rm -f xloa
	echo "#!"$(PERL)" -wI"$(xloalibdir) > xloa
	sed -e 's|DUMMY1|$(xloalibdir)|g' $(srcdir)/xloa.pl.in | \
	sed -e 's|DUMMY2|$(bindir)/loa|g' >> $(srcdir)/xloa;
	chmod ugo+x xloa



