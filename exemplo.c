#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a, *b;

  // Não vamos cagar nossa Brk!
  printf("Iniciando alocador...\n");

  iniciaAlocador();               // Impressão esperada
  imprimeMapa();                  // <vazio>

  a = (void *) alocaMem(10000);
  imprimeMapa();                  // ################**********

  b = (void *) alocaMem(4000);
  imprimeMapa();                  // ################**********##############****

  liberaMem(a);
  imprimeMapa();                  // ################----------##############****

  liberaMem(b);                   
  imprimeMapa();                  // ################----------------------------
                                  // ou
                                  // <vazio>
  finalizaAlocador();
}
