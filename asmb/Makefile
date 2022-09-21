CC = gcc
CFLAGS = -Wall -g

all: asmb.o
.PHONY : all clean

asmb.o: asmb.s
	$(CC) $(CFLAGS) -c -o asmb.o asmb.s

test: asmb.o test.c
	$(CC) $(CFLAGS) asmb.o -o test test.c

clean:
	rm -f asmb.o test

