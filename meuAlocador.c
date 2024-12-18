// Implementação da Biblioteca meuAlocador.h
#include <stdio.h>
#include <unistd.h>
#include "meuAlocador.h"

long int topoInicialHeap;
long int topoAtualHeap;

void iniciaAlocador()
{
   topoInicialHeap = sbrk(0);
   topoAtualHeap   = sbrk(0);
}

void finalizaAlocador()
{
   brk((void*) topoInicialHeap);
}

int liberaMem(void *bloco)
{
   void *percorreHeap;
   void *primeiroLivre;
   long int num_blocos;

   if (bloco <= topoInicialHeap || bloco > topoAtualHeap) return 0;
   
   // Uma única tacada:
   // Primeiros 08 Bytes do Header = ZERO
   *((long int*)(bloco - 16)) = 0;
   
   // Verifica se pode reduzir o BRK
   percorreHeap  = topoInicialHeap + 1;
   primeiroLivre = topoInicialHeap;
   while (percorreHeap < topoAtualHeap)
   {
      if ( *(long int*) percorreHeap == 1)
         primeiroLivre = percorreHeap;
      percorreHeap += *(long int*)(percorreHeap + 8) + 16;
   }

   // Caso 01: Heap está totalmente LIBERADA
   if (primeiroLivre == topoInicialHeap)
   {
      brk((void*)topoInicialHeap);
      topoAtualHeap = sbrk(0);
   }
   else
   {
      primeiroLivre += *(long int*)(primeiroLivre + 8) + 16;
      if (primeiroLivre < topoAtualHeap)
      {
         num_blocos = (topoAtualHeap + 1 - (long int) primeiroLivre) / 4096;
         brk((void*)(topoAtualHeap - num_blocos * 4096));
         topoAtualHeap = sbrk(0);
         *(long int*)(primeiroLivre + 8) = topoAtualHeap - (long int) primeiroLivre - 16;
      }
   }

   return 1;
}

void* alocaMem(int num_bytes)
{
   void *percorreHeap;
   void *ultimoBloco;
   void *melhorBloco;
   long int num_blocos;

   // Primeiro Passo: Percorrer a Heap e achar o MelhorBloco
   // ------------------------------------------------------
   // Se achar um MelhorBloco que caiba os Bytes, MelhorBloco = PercorreHeap
   // Caso contrário, MelhorBloco = NULL
   melhorBloco   = NULL;
   percorreHeap  = topoInicialHeap + 1;
   while (percorreHeap <= topoAtualHeap)
   {
      // Verifica se o bloco atual está LIVRE
      if ( *((long int *) percorreHeap) == 0 )
         // Verifica se o número de Bytes desejados "cabe" no bloco atual
         if ( *((long int*)(percorreHeap + 8)) >= num_bytes )
            // Verifica se o MelhorBloco não foi inicializado
            // ou se o bloco atual é o MelhorBloco
            if ( melhorBloco == NULL || *((long int*)(percorreHeap + 8)) < *((long int*)(melhorBloco + 8)) )
               melhorBloco = percorreHeap;
   
      // PercorreHeap += TAM_BLOCO + TAM_HEADER
      percorreHeap += *((long int*)(percorreHeap + 8)) + 16;
   }

   // Segundo Passo: Alocar os Bytes desejados na Heap
   // ------------------------------------------------
   // Se existe um MelhorBloco na Heap, aloca os Bytes no bloco 
   // e retorna o ponteiro para o bloco;
   // Se não existe, é necessário expandir a Heap aumentando o valor de brk
   // e então criar o bloco no final da Heap.

   // Caso 01: MelhorBloco EXISTE
   if (melhorBloco != NULL)
   {
      *((long int*) melhorBloco) = 1;
      if ( *((long int*)(melhorBloco + 8)) > num_bytes + 16 )
      {
         *((long int*)(melhorBloco + 16 + num_bytes)) = 0;
         *((long int*)(melhorBloco + 24 + num_bytes)) = *((long int*)(melhorBloco + 8)) - num_bytes - 16;
         *((long int*)(melhorBloco + 8)) = num_bytes;
      }
   }

   // Caso 02: MelhorBloco não EXISTE
   else
   {
      if (topoAtualHeap != topoInicialHeap)
      {
         // Acha o ENDEREÇO do ÚltimoBloco da Heap
         // Ou seja, ÚltimoBloco -> 1o Byte do HEADER
         ultimoBloco  = topoInicialHeap + 1;
         percorreHeap = ultimoBloco + *((long int*)(ultimoBloco + 8)) + 16;
         while (percorreHeap < topoAtualHeap)
         {
            ultimoBloco  = percorreHeap;
            percorreHeap = ultimoBloco + *((long int*)(ultimoBloco + 8)) + 16;
         }
      }
      else
         ultimoBloco = topoAtualHeap + 1;

      // Verifica quantos 4096B devem ser expandidos na brk:
      num_blocos = (long int)(ultimoBloco + 4111 + num_bytes - topoAtualHeap) / 4096;

      // Ajusta o novo bloco criado no final da Heap:
      // Puxa a brk para o final do bloco
      // Atribui o HEADER.VALIDO = 1
      // Atribui o HEADER.TAM_BLOCO = num_bytes
      brk((void*)(topoAtualHeap + num_blocos * 4096));
      topoAtualHeap = sbrk(0);
      *((long int*) ultimoBloco) = 1;
      *((long int*)(ultimoBloco + 8)) = num_bytes;

      *((long int*)(ultimoBloco + 16 + num_bytes)) = 0;
      *((long int*)(ultimoBloco + 24 + num_bytes)) = topoAtualHeap + 1 - (long int)(ultimoBloco + 32 + num_bytes);

      melhorBloco = ultimoBloco;
   }

   return (melhorBloco + 16);
}

void imprimeMapa()
{
   void *p;
   long int i, n_bytes;

   // Inicializa o ponteiro no início da Heap
   p = topoInicialHeap + 1;
   
   if (p >= topoAtualHeap)
      printf("<vazio>\n");

   while (p < topoAtualHeap)
   {
      n_bytes = *((long int*) (p + 8));

      // Imprime Cabeçalho
      for (i = 0; i < 15; ++i)
         printf("#");

      // Imprime Bytes
      // Caso o bloco esteja livre, imprime ----...
      // Se não, imprime ++++...
      if (*((long int*) p) == 0)
         for (i = 0; i < n_bytes; ++i)
            printf("-");
      else
         for (i = 0; i < n_bytes; ++i)
            printf("+");

      printf("\n");

      p += n_bytes + 16;
   }

   printf("\n");
}