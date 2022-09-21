CC = gcc
CFLAGS = 

.PHONY: all clean

all: parser

parser: parser.c parser.h lexer.c
	$(CC) $(CFLAGS) -o parser lexer.c parser.c

parser.c: parser.y lexer.c
	bison -d -t parser.y -o parser.c

lexer.c: lexer.l
	flex -o lexer.c lexer.l

clean:
	rm -f parser parser.c parser.h lexer.c