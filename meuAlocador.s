# Trabalho Software Básico - 2024/2
# Discentes:
# Leonardo Amorim Carpwiski    (GRR 20232331)
# Pedro Pinheiro Freitas Filho (GRR 2023????)

.section .data
   TOPO_INICIAL_HEAP:  .quad 0
   TOPO_ATUAL_HEAP:    .quad 0
   STR_HASH:           .string "#"
   STR_MAIS:           .string "+"
   STR_MENOS:          .string "-"
   STR_VAZIO:          .string "<vazio>\n"
   STR_NOVA_LINHA:     .string "\n"

.section .text
iniciaAlocador:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                      
   movq %rsp, %rbp                 
   movq $12, %rax                  # Syscall ID <- BRK    
   movq $0, %rdi                   # %rax <- Valor ATUAL de brk
   syscall                         # Executa SYSCALL BRK
   movq %rax, TOPO_INICIAL_HEAP    # topoInicialHeap = sbrk(0)
   movq %rax, TOPO_ATUAL_HEAP      # topoAtualHeap   = sbrk(0)
   # - - - - - - - - - - - - - -
   # Fim da Função
   popq %rbp                       
   ret                             

finalizaAlocador:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                   
   movq %rsp, %rbp              
   movq $12, %rax                  # Syscall ID <- BRK
   movq TOPO_INICIAL_HEAP, %rdi    # brk <- topoInicialHeap
   syscall                         # Executa SYSCALL BRK
   # - - - - - - - - - - - - - -
   # Fim da Função
   popq %rbp                    
   ret                          

liberaMem:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                   
   movq %rsp, %rbp              
   subq $24, %rsp                  
   # percorreHeap  -> -8(%rbp)
   # primeiroLivre -> -16(%rbp)
   # num_blocos    -> -24(%rbp)
   # bloco         -> +16(%rbp)

   # -if (bloco <= topoInicialHeap 
   #      || bloco > topoAtualHeap)
   #     return 0
   movq 16(%rbp), %rax
   movq TOPO_INICIAL_HEAP, %rbp
   cmpq %rbp, %rax
   jg fora_if_c1
   movq $0, %rax
   ret
fora_if_c1:
   movq TOPO_ATUAL_HEAP, %rbp
   cmpq %rbp, %rax
   jle fora_if_c2
   movq $0, %rax
   ret
fora_if_c2:
   # *(bloco - 16) = 0;
   movq 16(%rbp), %rax
   subq $16, %rax
   movq $0, (%rax)
   # percorreHeap  = topoInicialHeap + 1;
   # primeiroLivre = topoInicialHeap;
   # while (percorreHeap < topoAtualHeap)
   #    ...
   movq TOPO_INICIAL_HEAP, %rax
   addq $1, %rax
   movq %rax, -8(%rbp)
   movq TOPO_INICIAL_HEAP, %rbx
   movq %rbx, -16(%rbp)
while_percorre:
   movq -8(%rbp), %rax
   movq -16(%rbp), %rbx
   cmpq %rbx, %rax
   jge fora_while_percorre
   # -if (*percorreHeap == 1)
   #    primeiroLivre = percorreHeap;
   movq $1, %r10
   cmp %r10, %rax
   jne fora_if_aloc
   movq %rax, -16(%rbp)
fora_if_aloc:
   # percorreHeap += *(percorreHeap + 8) + 16;
   movq %rax, %rbx
   addq $8, %rbx
   movq (%rbx), %rbx
   addq $16, %rbx
   addq %rbx, %rax
   movq %rax, -8(%rbp)
fora_while_percorre:
   # -if (primeiroLivre == topoInicialHeap)
   #     ...
   # -else
   #     ...
   movq -16(%rbp), %rax
   movq TOPO_INICIAL_HEAP, %rbx
   cmpq %rbx, %rax
   jne else_heap_livre
   # brk(topoInicialHeap)
   movq $12, %rax
   movq TOPO_INICIAL_HEAP, %rdi
   syscall
   # topoAtualHeap = sbrk(0)
   movq $12, %rax
   movq $0, %rdi
   syscall
   movq %rax, TOPO_ATUAL_HEAP
   jmp fim_if_heap_livre
else_heap_livre:
   # primeiroLivre += *(primeiroLivre + 8) + 16
   movq -16(%rbp), %rax
   movq %rax, %rbx
   addq $8, %rbx
   movq (%rbx), %rbx
   addq $16, %rbx
   addq %rbx, %rax
   movq %rax, -16(%rbp)
   # -if (primeiroLivre < topoAtualHeap)
   #     ...
   movq TOPO_ATUAL_HEAP, %rbx
   cmp %rbx, %rax
   jge fim_if_heap_livre
   # num_blocos = (topoAtualHeap - primeiroLivre + 1) / 4096
   subq %rax, %rbx
   movq %rbx, %rax
   addq $1, %rax
   movq $0, %rdx # ESSA LINHA PODE DAR PROBLEMA?
   divq $4096
   movq %rax, -24(%rbp)
   # brk(topoAtualHeap - num_blocos * 4096)
   shl $12, %rax
   movq TOPO_ATUAL_HEAP, %rbx
   subq %rax, %rbx
   movq $12, %rax
   movq %rbx, %rdi
   syscall
   # topoAtualHeap = sbrk(0)
   movq %rbx, TOPO_ATUAL_HEAP
   # *(primeiroLivre + 8) = topoAtualHeap - (primeiroLivre + 16)
   movq -16(%rbp), %rax
   addq $16, %rax
   subq %rax, %rbx
   movq -16(%rbp), %rax
   addq $8, %rax
   movq %rbx, (%rax)
fim_if_heap_livre:
   # - - - - - - - - - - - - - -
   # Fim da Função
   addq $24, %rsp                  
   popq %rbp
   movq $1, %rax                    
   ret                           

alocaMem:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                   
   movq %rsp, %rbp              
   subq $32, %rsp                  
   # percorreHeap -> -8(%rbp)
   # ultimoBloco  -> -16(%rbp)
   # melhorBloco  -> -24(%rbp)
   # num_blocos   -> -32(%rbp)
   # num_bytes    -> +16(%rbp)

   # - - - - - - - - - - - - - -
   # Fim da Função 
   addq $32, %rsp                  
   popq %rbp                     
   ret                           

imprimeMapa:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                      
   movq %rsp, %rbp                 
   subq $24, %rsp                  
   # p       -> -8(%rbp)
   # i       -> -16(%rbp)
   # n_bytes -> -24(%rbp)

   # p := topoInicialHeap + 1
   movq TOPO_INICIAL_HEAP, %rax
   addq $1, %rax  
   # -if (p >= topoAtualHeap)
   #     printf("<vazio>\n");           
   movq %rax, -8(%rbp)             
   movq TOPO_ATUAL_HEAP, %rax      
   cmpq %rax, -8(%rbp)        
   jl fora_if                      
   movq STR_VAZIO, %rdi            
   call printf                
fora_if:
   # while (p < topoAtualHeap)
   #    ...
   movq TOPO_ATUAL_HEAP, %rax
while:
   # n_bytes := CONTEÚDO de p+8
   cmpq %rax, -8(%rbp)             
   jge fora_while
   movq -8(%rbp), %rax
   addq $8, %rax
   movq (%rax), %rbx
   movq %rbx, -24(%rbp)
   # for (i = 0; i < 15; ++i)
   #    printf("#"); 
   movq $0, -16(%rbp)
for_hash:
   movq -16(%rbp), %rax
   movq $15, %rbx
   cmpq %rbx, %rax
   jge fora_for_hash               
   movq STR_HASH, %rdi             
   call printf
   addq $1, %rax
   movq %rax, -16(%rbp)
   jmp for_hash
fora_for_hash:
   # -if ( *p == 0 ) -> Bloco LIVRE
   #    ...
   # -else
   #    ...
   movq -8(%rbp), %rax
   movq (%rax), %rax
   movq $0, %rbx
   cmpq %rbx, %rax                 
   jne else_livre
   # for (i = 0; i < n_bytes; ++i)
   #    printf("-");                
   movq $0, -16(%rbp)            
for_menos:                      
   movq -16(%rbp), %rax          
   movq -24(%rbp), %rbx          
   cmpq %rbx, %rax
   jge fora_if_livre
   movq STR_MENOS, %rdi
   call printf
   addq $1, %rax
   movq %rax, -16(%rbp)
   jmp for_menos
else_livre:
   # for (i = 0; i < n_bytes; ++i)
   #    printf("+");
   movq $0, -16(%rbp)
for_mais:
   movq -16(%rbp), %rax
   movq -24(%rbp), %rbx
   cmpq %rbx, %rax
   jge fora_if_livre
   movq STR_MAIS, %rdi
   call printf
   addq $1, %rax
   movq %rax, -16(%rbp)
   jmp for_mais
fora_if_livre:
   # p += n_bytes + 16
   movq -24(%rbp), %rax         
   movq -8(%rbp), %rbx          
   addq $16, %rax               
   addq %rax, %rbx              
   movq %rbx, -8(%rbp)                                  
fora_while:
   # printf("\n");
   movq STR_NOVA_LINHA, %rdi    
   call printf

   # - - - - - - - - - - - - - -
   # Fim da Função              
   addq $24, %rsp                  
   popq %rbp                       
   ret
