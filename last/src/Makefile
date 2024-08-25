CC=gcc

all: linux-version-sort curses linux-version-archbuild linux-version-num

curses : lib-display.* CSV_*.* Curses-*.*
	$(CC) lib-display.c CSV_ParseFile.c Curses-*.c -o ../curses/KRN_Curses

linux-version-archbuild: linux-version-archbuild*.*
	$(CC) linux-version-archbuild*.c 		-o ../linux-version-archbuild

linux-version-num: linux-version-num*.c linux-version-lib.*
	$(CC) linux-version-num*.c linux-version-lib.c 	-o ../linux-version-num

linux-version-sort: linux-version-sort*.c linux-version-lib.*
	$(CC) linux-version-sort*.c linux-version-lib.c -o ../linux-version-sort

