CC = gcc
CFLAGS = -Wall -g

all: asma.o
.PHONY : all clean

asma.o: asma.s
	$(CC) $(CFLAGS) -c -o asma.o asma.s

test: asma.o test.c
	$(CC) $(CFLAGS) asma.o -o test test.c

clean:
	rm -f asma.o test

