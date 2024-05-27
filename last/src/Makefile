CC=gcc

all: linux-version-sort curses

linux-version-sort: linux-version-sort*.c
	$(CC) linux-version-sort*.c -o ../linux-version-sort

curses : lib-display.* CSV_*.* Curses-*.*
	$(CC) lib-display.c CSV_ParseFile.c Curses-*.c -o ../curses/KRN_Curses
