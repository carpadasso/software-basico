#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a = NULL, *b = NULL;

  // Não vamos cagar nossa Brk!
  printf("Iniciando alocador...\n");

  iniciaAlocador();                 // Impressão esperada
  imprimeMapa();                    // <vazio>

  a = (void *) alocaMem(1000);
  imprimeMapa();                  // ################**********

  b = (void *) alocaMem(400);
  imprimeMapa();                  // ################**********##############****

  liberaMem(a);
  imprimeMapa();                  // ################----------##############****

  liberaMem(b);                   
  imprimeMapa();                  // ################----------------------------
                                    // ou
                                    // <vazio>
  finalizaAlocador();
}
