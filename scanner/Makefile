CC = gcc

.PHONY: all clean

all: scanner

scanner: main.c
	$(CC) -Wall main.c -lfl -o scanner

main.c: main.flex
	flex --outfile main.c main.flex

clean:
	rm -f scanner main.c