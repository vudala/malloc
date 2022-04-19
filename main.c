#include "meuAlocador.h"
#include <stdio.h>

int main() {
  long *a, *b, *c, *d;

  iniciaAlocador();

  imprimeBlocos();

  a = alocaMem(500);
  imprimeBlocos();

  b = alocaMem(8000);
  imprimeBlocos();

  c = alocaMem(64000);
  imprimeBlocos();

  liberaMem(c);
  imprimeBlocos();

  finalizaAlocador();

  return 0;
}
