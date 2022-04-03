#include "meuAlocador.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define STATE_LABEL_BYTES 8
#define SIZE_LABEL_BYTES  8
#define CHUNK_SIZE 2048
#define BRK_MEMORY_CHUNK STATE_LABEL_BYTES + SIZE_LABEL_BYTES + CHUNK_SIZE
long int FIM = 0, INICIO = 0;


long int brk(long int add){
    if (add)
        add = add + brk(0);

    long int dest;

    __asm__("movq %[Input], %%rdi" : : [Input] "rm" (add));
    __asm__("movq $12, %rax");
    __asm__("syscall");
    __asm__("movq %%rax, %[Destino]" : [Destino] "=rm" (dest));

    return dest;
}


void imprimirBloco(long int inicio){
    long int aux, estado, tamanho;
    __asm__("movq %[LabelTamanho], %[Output]" : [Output] "=r" (estado) : [LabelTamanho] "m" (inicio));
    aux = inicio + SIZE_LABEL_BYTES;
    __asm__("movq %[LabelTamanho], %[Output]" : [Output] "=r" (tamanho) : [LabelTamanho] "m" (aux));
    printf("Estado: %ld Tamanho: %ld\n", estado, tamanho);
}

void iniciaAlocador(){
    printf("START\n");
    INICIO = brk(0);
    FIM = brk(BRK_MEMORY_CHUNK);
    printf("%ld %ld\n", INICIO, FIM);
    /*
    Escreve o seguinte na estrutura :
    INICIO | 0 | 2048 | - - - - - - FREE MEMORY - - - - - - | FIM 
    */
    long int teste;
    __asm__("movq $0, %[inp]" : : [inp] "m" (INICIO));
    __asm__("movq %[inp], %[out]" : [out] "=r" (teste) : [inp] "m" (INICIO));
    printf("%ld\n", teste);

}


void finalizaAlocador(); 
int liberaMem(void* bloco); 
void* alocaMem(int num_bytes);
void imprimeMapa();