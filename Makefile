all: tictactoe

tictactoe: tictactoe.o
	ld -o $@ $^

tictactoe.o: tictactoe.asm
	nasm -f elf64 -g -F dwarf -o $@ $^

clean:
	rm -f tictactoe.o tictactoe