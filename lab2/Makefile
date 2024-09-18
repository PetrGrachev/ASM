all: 
	echo "ascending or descending mode?"

ascending_mode: 
	nasm -g -f elf64 lab.s -o lab.o -D ascending_mode
	ld -g -static lab.o -o lab.out
descending_mode:
	nasm -g -f elf64 lab.s -o lab.o -D descending_mode
	ld -static lab.o -o lab.out
