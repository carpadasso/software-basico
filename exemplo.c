#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a, *b;

  iniciaAlocador();               // Impressão esperada
  imprimeMapa();                  // <vazio>

  a = (void *) alocaMem(1000);
  imprimeMapa();                  // ################**********

  b = (void *) alocaMem(4);
  imprimeMapa();                  // ################**********##############****

  liberaMem(a);
  imprimeMapa();                  // ################----------##############****

  liberaMem(b);                   
  imprimeMapa();                  // ################----------------------------
                                  // ou
                                  // <vazio>
  finalizaAlocador();
}
