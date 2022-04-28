#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>
#include "meuAlocador.h"
 
int main(){
    printf("meu malloc totalmente original 100 por cento, confia\n");
    fflush(stdout);

    printf("casos de teste: \n");
    printf("case 1: derradeiro teste de fdp (mutiplas insercoes e remocoes requenciais com multiplas fusoes de blocos\n");
    printf("case 2: perda de ponteiro(desalocaçao de ponteiro atual)\n");
    printf("case 3: nextfit (verifica se o next fit esta funcionando)\n");
    printf("case 4: EU QUERO VER O CIRCO PEGANDO FOGO(5 MINUTOS NO INFERNO)\n");
    printf("case 5: um caso onde o nosso programa não deveria funcionar (double free)\n");
    printf("digite um numero entre 1 e 5 \n");
    int input;
    scanf("%i", &input);
    input = (input-1 % 5); 
    iniciaAlocador();
    void *a,*b ,*c, *d, *e, *f; 
    int *coisa[50];
    for (int i = 0; i < 50; ++i){
        coisa[i] = NULL;
    }
    int op = 0;
    int k = 0;
    srand(time(NULL));
    
    switch (input){
    case 0:
        //Teste noia
        for (int j = 0; j < 5; ++j){
            for (int i = 0; i < 50; ++i){
                coisa[i] = (int*) alocaMem((i+1)*sizeof(int));   
                printf("aqui tem %i \n" ,i);
                fflush(stdout);  
            }
            imprimeMapa();

            for (int i = 0; i < 50; i+= 2){
                liberaMem(coisa[i]);   
                printf("aqui liberamos %i \n" ,i);
                fflush(stdout);  
            }
            imprimeMapa();

            for (int i = 1; i < 50; i+= 2){
                liberaMem(coisa[i]);   
                printf("aqui liberamos %i \n" ,i);
                fflush(stdout);  
                
            }
            imprimeMapa();
        }
        finalizaAlocador();
        break;
    case 1:
           
        //Teste fácil (teoricamente)
        a=alocaMem(50);   
        printf("aqui tem 50 \n");
        fflush(stdout);  
        imprimeMapa();
        b=alocaMem(240);     
        printf("aqui tem 240 \n");
        fflush(stdout); 
        imprimeMapa();
        c=alocaMem(50);     
        printf("aqui tem 50 \n");
        fflush(stdout); 
        imprimeMapa();
        printf("aqui liberamos 240 \n");
        liberaMem(b);
        fflush(stdout); 
        imprimeMapa();
        b=alocaMem(100); 
        printf("aqui tem 100 \n");
        fflush(stdout);  
        imprimeMapa();
        printf("aqui liberamos 50 \n");
        liberaMem(c);
        fflush(stdout); 
        imprimeMapa();
        printf("aqui liberamos 100 \n");
        liberaMem(b);
        fflush(stdout); 
        imprimeMapa();
        d=alocaMem(30); 
        printf("aqui tem 30 \n");
        fflush(stdout);  
        imprimeMapa();
        finalizaAlocador();
    break;
    case 2:    
        iniciaAlocador();
        a=alocaMem(50);   
        printf("aqui tem 50 \n");
        fflush(stdout);  
        imprimeMapa();     
        b=alocaMem(240);
        printf("aqui tem 240 \n");
        fflush(stdout); 
        imprimeMapa();
        c=alocaMem(50);
        printf("aqui tem 50 \n");
        fflush(stdout); 
        imprimeMapa();
        liberaMem(b);
        printf("aqui liberamos 240 \n");
        fflush(stdout); 
        imprimeMapa();
        d=alocaMem(100);
        printf("aqui tem 100 \n");
        fflush(stdout); 
        imprimeMapa();
        f=alocaMem(50);
        printf("aqui alocamos 50 \n");
        fflush(stdout);
        imprimeMapa();
        liberaMem(c);
        printf("aqui liberamos 50 \n");
        fflush(stdout); 
        imprimeMapa();
        liberaMem(d);
        printf("aqui liberamos 100 \n");
        fflush(stdout); 
        imprimeMapa();
        liberaMem(a);
        printf("aqui liberamos 50 \n");
        fflush(stdout); 
        imprimeMapa();
        e=alocaMem(50);
        printf("aqui alocamos 50 \n");
        fflush(stdout);
        imprimeMapa();
        finalizaAlocador();
    break;

    case 3:
        
        for (int j = 0; j< 300; j++){
            op = rand() % 2 ;
            if (op == 1){
                k = (rand() % 50);
                if (coisa[k] == NULL){
                    int size =((rand() % 100)+1)*sizeof(int);
                    coisa[k] = alocaMem(size);
                    printf("aqui alocamos %i \n", size);
                    fflush(stdout);
                    imprimeMapa();
                }
            }
            if (op == 0){
                k = (rand() % 50);
                if (coisa[k] != NULL){
                    int size = liberaMem(coisa[k]);
                    coisa[k] = NULL;
                    printf("aqui liberamos um bloco de %i bytes \n", size);
                    fflush(stdout);
                }
            }
            imprimeMapa();
        }
    break;

    case 4:
        c=alocaMem(50);
        printf("aqui tem c = 50 \n");
        fflush(stdout); 
        imprimeMapa();
        liberaMem(c);
        printf("aqui liberamos c= 50 \n");
        fflush(stdout); 
        imprimeMapa();
        a=alocaMem(20);
        printf("aqui tem a = 20 \n");
        fflush(stdout); 
        imprimeMapa();
        liberaMem(c);
        printf("aqui liberamos c de novo \n");
        fflush(stdout); 
        imprimeMapa();
    break; 
    }

}