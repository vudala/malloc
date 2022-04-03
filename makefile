all:
	gcc -c teste.s 
	gcc -no-pie -nostartfiles teste.o
