CC = gcc
CFLAGS =

.PHONY: all clean test

all: ag

ag: y.tab.c lex.yy.c vector.o
	$(CC) $(CFLAGS) -o ag y.tab.c lex.yy.c vector.o

vector.o: vector.c vector.h
	gcc -g -c -pedantic -Wall vector.c

oxout.y oxout.l: gram.y scanner.l 
	ox gram.y scanner.l

y.tab.c y.tab.h: oxout.y
	yacc -d -v oxout.y

lex.yy.c: oxout.l
	flex oxout.l

clean:
	rm -f oxout.* lex.yy.c y.tab.* ag *.o y.output

test:
	/usr/ftp/pub/ubvl/test/ag/test