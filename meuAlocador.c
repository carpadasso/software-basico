// Implementação da Biblioteca meuAlocador.h
#include <stdio.h>
#include "meuAlocador.h"

long int topoInicialHeap;
long int topoAtualHeap;

void iniciaAlocador()
{
   topoInicialHeap = brk(0);
   topoAtualHeap   = brk(0);
}

void finalizaAlocador()
{
   brk(topoInicialHeap);
}

int liberaMem(void *bloco)
{
   if (bloco <= topoInicialHeap) return 0;
   
   // Uma única tacada:
   // Primeiros 08 Bytes do Header = ZERO
   *((long int*) bloco) = 0;
   
   // Verifica se pode reduzir o BRK
   // < Código disso ae . . . >

   return 1;
}

void* alocaMem(int num_bytes)
{
   void *percorreHeap;
   void *ultimoBloco;
   void *melhorBloco;
   void *aux;

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
         aux = melhorBloco;
         *((long int*)(aux + 16 + num_bytes)) = 0;
         *((long int*)(aux + 32 + num_bytes)) = *((long int*)(melhorBloco + 1)) - num_bytes - 16;
         *((long int*)(melhorBloco + 1)) = num_bytes;
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
      num_blocos = *((long int*)(ultimoBloco + 4111 + num_bytes - topoAtualHeap)) / 4096;

      // Ajusta o novo bloco criado no final da Heap:
      // Puxa a brk para o final do bloco
      // Atribui o HEADER.VALIDO = 1
      // Atribui o HEADER.TAM_BLOCO = num_bytes
      brk(topoAtualHeap + num_blocos * 4096);
      topoAtualHeap = brk(0);
      *((long int*) ultimoBloco) = 1;
      *((long int*)(ultimoBloco + 8)) = num_bytes;

      aux = ultimoBloco;
      *((long int*)(aux + 16 + num_bytes)) = 0;
      *((long int*)(aux + 32 + num_bytes)) = topoAtualHeap - *(long int*)(aux + 32 + num_bytes);
      *((long int*)(ultimoBloco + 8)) = num_bytes;

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
      
      p += n_bytes + 16;
   }
}