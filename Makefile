all:
	as meuAlocador.s -o meuAlocador.o
	gcc -g -c main.c -o main.o
	gcc -static main.o meuAlocador.o -o meuAlocador


clean:
	rm -rf  *.o


purge: clean
	rm -rf meuAlocador