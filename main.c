#include "meuAlocador.h"
#include <stdio.h>

int main() {
  long *a, *b, *c, *d, *e, *f;

  iniciaAlocador();

  imprimeBlocos();
  a=alocaMem(240);
  imprimeBlocos();
  b=alocaMem(6000);
  imprimeBlocos();


  finalizaAlocador();

  return 0;
}
