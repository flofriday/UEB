CC = gcc
MYFLAGS = -pedantic -Wall  # Flags for my sourcecode, where I am more strict about the warnings
CFLAGS = -g

.PHONY: all clean test

all: gesamt

gesamt: y.tab.c lex.yy.c vector.o tree.o generator.o codegen.o
	$(CC) $(CFLAGS) -o gesamt codegen.o generator.o y.tab.c lex.yy.c vector.o tree.o

codegen.o: codegen.c
	$(CC) $(CFLAGS) -c codegen.c

codegen.c: codegen.bfe
	bfe < codegen.bfe | iburg > codegen.c

generator.o: generator.c generator.h
	$(CC) $(CFLAGS) $(MYFLAGS) -c generator.c

tree.o: tree.c tree.h
	$(CC) $(CFLAGS) $(MYFLAGS) -c tree.c

vector.o: vector.c vector.h
	$(CC) $(CFLAGS) $(MYFLAGS) -c vector.c

oxout.y oxout.l: gram.y scanner.l 
	ox gram.y scanner.l

y.tab.c y.tab.h: oxout.y
	yacc -d -v oxout.y

lex.yy.c: oxout.l
	flex oxout.l

clean:
	rm -f gesamt oxout.* lex.yy.c y.tab.* *.o y.output codegen.c test*.s

test:
	/usr/ftp/pub/ubvl/test/gesamt/test