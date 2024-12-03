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
.globl iniciaAlocador
iniciaAlocador:
   pushq %rbp                      
   movq %rsp, %rbp   
   # Início da Função
   # - - - - - - - - - - - - - -    

   movq $12, %rax                            # %RAX := Syscall ID de BRK    
   movq $0, %rdi                             # %RDI := 0 (ou seja, VALOR ATUAL DE BRK)
   syscall                                   # EXECUTA SYSCALL BRK
   movq %rax, TOPO_INICIAL_HEAP              # topoInicialHeap = VALOR ATUAL DE BRK
   movq %rax, TOPO_ATUAL_HEAP                # topoAtualHeap   = VALOR ATUAL DE BRK

   # - - - - - - - - - - - - - -
   # Fim da Função
   popq %rbp                       
   ret                             

.globl finalizaAlocador
finalizaAlocador:
   pushq %rbp                   
   movq %rsp, %rbp     
   # Início da Função
   # - - - - - - - - - - - - - -   

   movq $12, %rax                            # %RAX := Syscall ID de BRK 
   movq TOPO_INICIAL_HEAP, %rdi              # %RDI := topoInicialHeap (ou seja, BRK := topoInicialHeap)
   syscall                                   # EXECUTA SYSCALL BRK

   # - - - - - - - - - - - - - -
   # Fim da Função
   popq %rbp                    
   ret                          

.globl liberaMem
liberaMem:
   # Início da Função
   # - - - - - - - - - - - - - -
   pushq %rbp                   
   movq %rsp, %rbp              
   subq $24, %rsp           
   # percorreHeap  -> -8(%rbp)
   # primeiroLivre -> -16(%rbp)
   # num_blocos    -> -24(%rbp)
   # bloco         -> %rdi

   # -if (bloco <= topoInicialHeap 
   #      || bloco > topoAtualHeap)
   #     return 0
   movq %rdi, %rax                           # %RAX := bloco
   movq TOPO_INICIAL_HEAP, %rbx              # %RBX := topoInicialHeap
   cmpq %rbx, %rax                           # COMPARA bloco e topoInicialHeap
   jg if_condicao_2                          # SE bloco > topoInicialHeap, PULA PARA A 2a CONDIÇÃO
   addq $24, %rsp                            # RESTANTE: RETORNA 0
   popq %rbp
   movq $0, %rax
   ret
if_condicao_2:
   movq TOPO_ATUAL_HEAP, %rbx                # %RBX := topoAtualHeap
   cmpq %rbx, %rax                           # COMPARA bloco e topoAtualHeap
   jle fora_if_bloco_invalido                # SE bloco <= topoAtualHeap, SAI DO IF
   addq $24, %rsp                            # RESTANTE: RETORNA 0
   popq %rbp
   movq $0, %rax
   ret
fora_if_bloco_invalido:
   # *(bloco - 16) = 0;
   movq %rdi, %rax                           # %RAX := bloco
   subq $16, %rax                            # %RAX := bloco - 16
   movq $0, (%rax)                           # *(bloco - 16) := 0
   # percorreHeap  = topoInicialHeap + 1;
   # primeiroLivre = topoInicialHeap;
   # while (percorreHeap < topoAtualHeap)
   #    ...
   movq TOPO_INICIAL_HEAP, %rax              # %RAX := topoInicialHeap
   addq $1, %rax                             # %RAX := topoInicialHeap + 1
   movq %rax, -8(%rbp)                       # percorreHeap := topoInicialHeap + 1
   movq TOPO_INICIAL_HEAP, %rbx              # %RBX := topoInicialHeap
   movq %rbx, -16(%rbp)                      # primeiroLivre := topoInicialHeap
while_percorre_heap:
   movq -8(%rbp), %rax                       # %RAX := percorreHeap
   movq TOPO_ATUAL_HEAP, %rbx                # %RBX := topoAtualHeap
   cmpq %rbx, %rax                           # COMPARA percorreHeap e topoAtualHeap
   jge fora_while_percorre_heap              # SE percorreHeap >= topoAtualHeap, SAI DO WHILE
   # -if (*percorreHeap == 1)
   #    primeiroLivre = percorreHeap;
   movq $1, %rbx                             # %RBX := 1
   movq (%rax), %rax                         # %RAX := *(percorreHeap)
   cmpq %rbx, %rax                           # COMPARA *(percorreHeap) e 1
   jne fora_if_alocado                       # SE *(percorreHeap) != 1, SAI DO IF
   movq -8(%rbp), %rax                       # %RAX := percorreHeap
   movq %rax, -16(%rbp)                      # primeiroLivre := percorreHeap (que está em %RAX)
fora_if_alocado:
   # percorreHeap += *(percorreHeap + 8) + 16;
   movq -8(%rbp), %rax                       # %RAX := percorreHeap
   movq %rax, %rbx                           # %RBX := percorreHeap
   addq $8, %rbx                             # %RBX := percorreHeap + 8
   movq (%rbx), %rbx                         # %RBX := *(percorreHeap + 8)
   addq $16, %rbx                            # %RBX := *(percorreHeap + 8) + 16
   addq %rbx, %rax                           # %RAX := percorreHeap + *(percorreHeap + 8) + 16
   movq %rax, -8(%rbp)                       # percorreHeap := percorreHeap + *(percorreHeap + 8) + 16
   jmp while_percorre_heap                   # VOLTA INÍCIO DO WHILE
fora_while_percorre_heap:
   # -if (primeiroLivre == topoInicialHeap)
   #     ...
   # -else
   #     ...
   movq -16(%rbp), %rax                      # %RAX := primeiroLivre
   movq TOPO_INICIAL_HEAP, %rbx              # %RBX := topoInicialHeap
   cmpq %rbx, %rax                           # COMPARA primeiroLivre e topoInicialHeap
   jne else_heap_livre                       # SE primeiroLivre != topoInicialHeal, PULA PARA O ELSE
   # brk(topoInicialHeap)
   pushq %rdi
   movq $12, %rax                            # %RAX := Syscall ID de BRK
   movq TOPO_INICIAL_HEAP, %rdi              # %RDI := topoInicialHeap (ou seja, BRK := topoInicialHeal)
   syscall                                   # EXECUTA SYSCALL BRK
   popq %rdi
   # topoAtualHeap = sbrk(0)
   pushq %rdi
   movq $12, %rax                            # %RAX := Syscall ID de BRK        
   movq $0, %rdi                             # %RDI := 0 (ou seja, %RAX := BRK)
   syscall                                   # EXECUTA SYSCALL BRK
   popq %rdi
   movq %rax, TOPO_ATUAL_HEAP                # topoAtualHeap := BRK
   jmp fim_if_heap_livre                     # SAI DO IF
else_heap_livre:
   # primeiroLivre += *(primeiroLivre + 8) + 16
   movq -16(%rbp), %rax                      # %RAX := primeiroLivre
   movq %rax, %rbx                           # %RBX := primeiroLivre
   addq $8, %rbx                             # %RBX := primeiroLivre + 8
   movq (%rbx), %rbx                         # %RBX := *(primeiroLivre + 8)
   addq $16, %rbx                            # %RBX := *(primeiroLivre + 8) + 16
   addq %rbx, %rax                           # %RAX := primeiroLivre + *(primeiroLivre + 8) + 16
   movq %rax, -16(%rbp)                      # primeiroLivre := primeiroLivre + *(primeiroLivre + 8) + 16
   # if (primeiroLivre < topoAtualHeap)
   #     ...
   movq TOPO_ATUAL_HEAP, %rbx                # %RBX := topoAtualHeap
   cmpq %rbx, %rax                           # COMPARA primeiroLivre e topoAtualHeap 
   jge fim_if_heap_livre                     # SE primeiroLivre >= topoAtualHeap, SAI DO IF
   # num_blocos = (topoAtualHeap - primeiroLivre + 1) / 4096
   subq %rax, %rbx                           # %RBX := topoAtualHeap - primeiroLivre
   movq %rbx, %rax                           # %RAX := topoAtualHeap - primeiroLivre
   addq $1, %rax                             # %RAX := topoAtualHeap - primeiroLivre + 1
   shr $12, %rax                             # %RAX := (topoAtualHeap - primeiroLivre + 1) / 4096
   movq %rax, -24(%rbp)                      # num_blocos := (topoAtualHeap - primeiroLivre + 1) / 4096
   # brk(topoAtualHeap - num_blocos * 4096)
   shl $12, %rax                             # %RAX := num_blocos * 4096
   movq TOPO_ATUAL_HEAP, %rbx                # %RBX := topoAtualHeap
   subq %rax, %rbx                           # %RBX := topoAtualHeap - num_blocos * 4096
   pushq %rdi
   movq $12, %rax                            # %RAX := Syscall ID de BRK
   movq %rbx, %rdi                           # %RDI := topoAtualHeap - num_blocos * 4096 (ou seja, BRK := topoAtualHeap - num_blocos * 4096)
   syscall                                   # EXECUTA SYSCALL BRK
   popq %rdi
   # topoAtualHeap = sbrk(0)
   movq %rax, TOPO_ATUAL_HEAP                # topoAtualHeap := BRK (que está em %RAX)
   # *(primeiroLivre + 8) = topoAtualHeap - (primeiroLivre + 16)
   movq -16(%rbp), %rax                      # %RAX := primeiroLivre
   addq $16, %rax                            # %RAX := primeiroLivre + 16
   subq %rax, %rbx                           # %RBX := topoAtualHeap - (primeiroLivre + 16)
   movq -16(%rbp), %rax                      # %RAX := primeiroLivre
   addq $8, %rax                             # %RAX := primeiroLivre + 8
   movq %rbx, (%rax)                         # *(primeiroLivre + 8) := topoAtualHeap - (primeiroLivre + 16)
fim_if_heap_livre:
   # - - - - - - - - - - - - - -
   # Fim da Função
   addq $24, %rsp                  
   popq %rbp
   movq $1, %rax                    
   ret                           

.globl alocaMem
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
   # num_bytes    -> %rdi

   # melhorBloco   = NULL;
   movq $0, -24(%rbp)                       # melhorBloco := 0
   # percorreHeap  = topoInicialHeap + 1;
   movq TOPO_INICIAL_HEAP, %rax             # %RAX := topoInicialHeap
   addq $1, %rax                            # %RAX := topoInicialHeap + 1
   movq %rax, -8(%rbp)                      # percorreHeap := topoInicialHeap + 1 (que está em %RAX)
   # while (percorreHeap <= topoAtualHeap)
   #    ...
while_percorre_aloca_mem:
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   cmpq %rbx, %rax                          # COMPARA percorreHeap com topoAtualHeap
   jg fim_while_percorre_aloca_mem          # SE percorreHeap > topoAtualHeap, SAI DO WHILE
   # -if ( *percorreHeap == 0 )
   #     ...
   movq (%rax), %rax                        # %RAX = *percorreHeap
   movq $0, %rbx                            # %RBX := 0
   cmpq %rbx, %rax                          # COMPARA *percorreHeap e 0
   jne fim_if                               # SE *percorreHeap != 0, SAI DO IF
   # -if ( *(percorreHeap + 8) >= num_bytes ) 
   #    ...
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   addq $8, %rax                            # %RAX := percorreHeap + 8
   movq (%rax), %rax                        # %RAX := *(percorreHeap + 8)
   movq %rdi, %rbx                          # %RBX := num_bytes
   cmpq %rbx, %rax                          # COMPARA *(percorreHeap) e num_bytes
   jl fim_if                                # SE *(percorreHeap) < num_bytes, SAI DO LAÇO
   # -if ( melhorBloco == NULL || 
   #       *(percorreHeap + 8) < *(melhorBloco + 8) )
   #     melhorBloco = percorreHeap;
   movq $0, %rbx                            # %RBX := 0
   movq -24(%rbp), %rax                     # %RAX := melhorBloco
   cmpq %rbx, %rax                          # COMPARA melhorBloco e 0
   jne if_cond_2                            # SE melhorBloco != 0, PULA PARA 2a CONDIÇÃO
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   movq %rax, -24(%rbp)                     # melhorBloco := percorreHeap (que está em %RAX)
if_cond_2:
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   addq $8, %rax                            # %RAX := percorreHeap + 8
   movq (%rax), %rax                        # %RAX = *(percorreHeap + 8)
   movq -24(%rbp), %rbx                     # %RBX := melhorBloco
   addq $8, %rbx                            # %RBX := melhorBloco + 8
   movq (%rbx), %rbx                        # %RBX := *(melhorBloco + 8)
   cmpq %rbx, %rax                          # COMPARA *(percorreHeap + 8) e *(melhorBloco + 8)
   jge fim_if                               # SE *(percorreHeap + 8) >= *(melhorBloco + 8), SAI DO IF
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   movq %rax, -24(%rbp)                     # melhorBloco := percorreHeap (que está em %RAX)
fim_if:
   # percorreHeap += *(percorreHeap + 8) + 16;
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   movq %rax, %rbx                          # %RBX := percorreHeap
   addq $8, %rbx                            # %RBX := percorreHeap + 8
   movq (%rbx), %rbx                        # %RBX := *(percorreHeap + 8)
   addq $16, %rbx                           # %RBX := *(percorreHeap + 8) + 16
   addq %rbx, %rax                          # %RAX := percorreHeap + *(percorreHeap + 8) + 16
   movq %rax, -8(%rbp)                      # percorreHeap := percorreHeap + *(percorreHeap + 8) + 16
   jmp while_percorre_aloca_mem
fim_while_percorre_aloca_mem:
   # -if (melhorBloco != NULL)
   #     ...
   movq -24(%rbp), %rax                     # %RAX := melhorBloco
   movq $0, %rbx                            # %RBX := 0
   cmpq %rbx, %rax                          # COMPARA melhorBloco e 0
   je else_melhor_bloco                     # SE melhorBloco == 0, PULA PARA O ELSE
   # *melhorBloco = 1;
   movq $1, (%rax)                          # *(melhorBloco) := 1
   # if ( *(melhorBloco + 8) > num_bytes + 16 )
   addq $8, %rax                            # %RAX := melhorBloco + 8
   movq (%rax), %rax                        # %RAX := *(melhorBloco + 8)
   movq %rdi, %rbx                          # %RBX := num_bytes
   addq $16, %rbx                           # %RBX := num_bytes + 16
   cmpq %rbx, %rax                          # COMPARA *(melhorBloco + 8) e num_bytes + 16
   jle fim_if_melhor_bloco                  # SE *(melhorBloco + 8) <= num_bytes + 16, SAI DO IF
   # *(melhorBloco + 16 + num_bytes) = 0;
   movq -24(%rbp), %rax                     # %RAX := melhorBloco
   movq %rdi, %rbx                          # %RBX := num_bytes
   addq $16, %rax                           # %RAX := melhorBloco + 16
   addq %rbx, %rax                          # %RAX := melhorBloco + 16 + num_bytes
   movq $0, (%rax)                          # *(melhorBloco + 16 + num_bytes) := 0
   # *(melhorBloco + 24 + num_bytes) = *(melhorBloco + 8) - (num_bytes + 16);
   movq -24(%rbp), %rax                     # %RAX := melhorBloco
   addq $8, %rax                            # %RAX := melhorBloco + 8
   movq (%rax), %rax                        # %RAX := *(melhorBloco + 8)
   movq %rdi, %rbx                          # %RBX := num_bytes
   addq $16, %rbx                           # %RBX := num_bytes + 16
   subq %rbx, %rax                          # %RAX := *(melhorBloco + 8) - (num_bytes + 16)
   movq -24(%rbp), %rbx                     # %RBX := melhorBloco
   movq %rdi, %r10                          # %R10 := num_bytes
   addq $24, %rbx                           # %RBX := melhorBloco + 24
   addq %r10, %rbx                          # %RBX := melhorBloco + 24 + num_bytes
   movq %rax, (%rbx)                        # *(melhorBloco + 24 + num_bytes) := *(melhorBloco + 8) - (num_bytes + 16)
   # *(melhorBloco + 8) = num_bytes;
   movq %rdi, %rax                          # %RAX := num_bytes
   movq -24(%rbp), %rbx                     # %RBX := melhorBloco
   addq $8, %rbx                            # %RBX := melhorBloco + 8
   movq %rax, (%rbx)                        # *(melhorBloco + 8) := num_bytes
   jmp fim_if_melhor_bloco                  # SAI DO IF
else_melhor_bloco:
   # -if (topoAtualHeap != topoInicialHeap)
   #    ...
   movq TOPO_ATUAL_HEAP, %rax               # %RAX := topoAtualHeap
   movq TOPO_INICIAL_HEAP, %rbx             # %RBX := topoInicialHeap
   cmpq %rbx, %rax                          # COMPARA topoAtualHeap e topoInicialHeap
   je else_ultimo_bloco                     # SE topoAtualHeap == topoInicialHeap, PULA PARA O ELSE
   # ultimoBloco  = topoInicialHeap + 1;
   movq TOPO_INICIAL_HEAP, %rax             # %RAX := topoInicialHeap 
   addq $1, %rax                            # %RAX := topoInicialHeap + 1
   movq %rax, -16(%rbp)                     # ultimoBloco := topoInicialHeap + 1
   # percorreHeap = ultimoBloco + *(ultimoBloco + 8) + 16;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   movq %rax, %rbx                          # %RBX := ultimoBloco
   addq $8, %rbx                            # %RBX := ultimoBloco + 1
   movq (%rbx), %rbx                        # %RBX := *(ultimoBloco + 1)
   addq $16, %rax                           # %RBX := *(ultimoBloco + 1) + 16
   addq %rbx, %rax                          # %RAX := ultimoBloco + *(ultimoBloco + 1) + 16
   movq %rax, -8(%rbp)                      # percorreHeap := ultimoBloco + *(ultimoBloco + 1) + 16
   # while (percorreHeap < topoAtualHeap)
while_ultimo_bloco:
   movq -8(%rbp), %rax                      # %RAX := percorreHeap
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   cmpq %rbx, %rax                          # COMPARA percorreHeap e topoAtualHeap
   jge fim_if_ultimo_bloco                  # SE percorreHeap >= topoAtualHeap, SAI DO WHILE
   # ultimoBloco  = percorreHeap;
   movq %rax, -16(%rbp)                     # ultimoBloco := percorreHeap
   # percorreHeap = ultimoBloco + *(ultimoBloco + 8) + 16;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   movq %rax, %rbx                          # %RBX := ultimoBloco
   addq $8, %rbx                            # %RBX := ultimoBloco + 8
   movq (%rbx), %rbx                        # %RBX := *(ultimoBloco + 8)
   addq $16, %rbx                           # %RBX := *(ultimoBloco + 8) + 16
   addq %rbx, %rax                          # %RAX := ultimoBloco + *(ultimoBloco + 8) + 16
   movq %rax, -8(%rbp)                      # percorreHeap := ultimoBloco + *(ultimoBloco + 8) + 16
   jmp while_ultimo_bloco                   # VOLTA INÍCIO DO WHILE
else_ultimo_bloco:
   # ultimoBloco = topoAtualHeap + 1;
   movq TOPO_ATUAL_HEAP, %rax               # %RAX := topoAtualHeap
   addq $1, %rax                            # %RAX := topoAtualHeap + 1
   movq %rax, -16(%rbp)                     # ultimoBloco := topoAtualHeap + 1
fim_if_ultimo_bloco:
   # num_blocos = (ultimoBloco + 4111 + num_bytes - topoAtualHeap) / 4096;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   addq $4111, %rax                         # %RAX := ultimoBloco + 4111
   movq %rdi, %rbx                          # %RBX := num_bytes
   addq %rbx, %rax                          # %RAX := ultimoBloco + 4111 + num_bytes
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   subq %rbx, %rax                          # %RAX := ultimoBloco + 4111 + num_bytes - topoAtualHeap
   shr $12, %rax                            # %RAX := (ultimoBloco + 4111 + num_bytes - topoAtualHeap) / 4096
   movq %rax, -32(%rbp)                     # num_blocos := (ultimoBloco + 4111 + num_bytes - topoAtualHeap) / 4096
   # brk(topoAtualHeap + num_blocos * 4096);
   shl $12, %rax                            # %RAX := num_blocos * 4096
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   addq %rbx, %rax                          # %RAX := topoAtualHeap + num_blocos * 4096
   pushq %rdi
   movq %rax, %rdi                          # %RDI := topoAtualHeap + num_blocos * 4096 (ou seja, BRK := topoAtualHeap + num_blocos * 4096)
   movq $12, %rax                           # %RAX := Syscall ID de BRK
   syscall                                  # EXECUTA SYSCALL BRK
   popq %rdi
   # topoAtualHeap = sbrk(0);                
   movq %rax, TOPO_ATUAL_HEAP               # topoAtualHeap := BRK (que está em %RAX)
   # *ultimoBloco = 1;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   movq $1, (%rax)                          # *(ultimoBloco) := 1
   # *(ultimoBloco + 8) = num_bytes;
   movq %rdi, %rax                          # %RAX := num_bytes
   movq -16(%rbp), %rbx                     # %RBX := ultimoBloco
   addq $8, %rbx                            # %RBX := ultimoBloco + 8
   movq %rax, (%rbx)                        # *(ultimoBloco + 8) := num_bytes
   # *(ultimoBloco + 16 + num_bytes) = 0;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   movq %rdi, %rbx                          # %RBX := num_bytes
   addq $16, %rax                           # %RAX := ultimoBloco + 16
   addq %rbx, %rax                          # %RAX := ultimoBloco + 16 + num_bytes
   movq $0, (%rax)                          # *(ultimoBloco + 16 + num_bytes) := 0
   # *(ultimoBloco + 24 + num_bytes) = topoAtualHeap + 1 - (ultimoBloco + 32 + num_bytes);
   movq -16(%rbp), %rbx                     # %RBX := ultimoBLoco
   movq %rdi, %rax                          # %RAX := num_bytes
   addq $32, %rbx                           # %RBX := ultimoBloco + 32
   addq %rax, %rbx                          # %RBX := ultimoBloco + 32 + num_bytes
   movq TOPO_ATUAL_HEAP, %rax               # %RAX := topoAtualHeap
   addq $1, %rax                            # %RAX := topoAtualHeap + 1
   subq %rbx, %rax                          # %RAX := topoAtualHeap + 1 - (ultimoBloco + 32 + num_bytes)
   movq -16(%rbp), %rbx                     # %RBX := ultimoBloco
   addq $24, %rbx                           # %RBX := ultimoBloco + 24
   movq %rdi, %r10                          # %R10 := num_bytes
   addq %r10, %rbx                          # %RBX := ultimoBloco + 24 + num_bytes
   movq %rax, (%rbx)                        # *(ultimoBloco + 24 + num_bytes) = topoAtualHeap + 1 - (ultimoBloco + 32 + num_bytes)
   # melhorBloco = ultimoBloco;
   movq -16(%rbp), %rax                     # %RAX := ultimoBloco
   movq %rax, -24(%rbp)                     # melhorBloco := ultimoBloco (que está em %RAX)
fim_if_melhor_bloco:
   # return (melhorBloco + 16);
   movq -24(%rbp), %rax                     # %RAX := melhorBloco
   addq $16, %rax                           # %RAX := melhorBloco + 16
   # - - - - - - - - - - - - - -
   # Fim da Função 
   addq $32, %rsp                  
   popq %rbp                     
   ret                           

.globl imprimeMapa
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
   movq TOPO_INICIAL_HEAP, %rax             # %RAX := topoInicialHeap
   addq $1, %rax                            # %RAX := topoInicialHeap + 1
   movq %rax, -8(%rbp)                      # p := topoInicialHeap + 1

   # -if (p >= topoAtualHeap)
   #     printf("<vazio>\n");
   movq -8(%rbp), %rax                        
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   cmpq %rbx, %rax                          # COMPARA p e topoAtualHeap
   jl while_imprime_heap                    # SE p < topoAtualHeap, SAI DO IF

   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_VAZIO, %rdi                    # %RDI := "<vazio>\n"
   call printf                              # IMPRIME "<vazio>\n" NA TELA

   # while (p < topoAtualHeap)
   #    ...
while_imprime_heap:
   movq -8(%rbp), %rax                      # %RAX := p
   movq TOPO_ATUAL_HEAP, %rbx               # %RBX := topoAtualHeap
   cmpq %rbx, %rax                          # COMPARA p e topoAtualHeap
   jge fora_while_imprime_heap              # SE p >= topoAtualHeap, SAI DO WHILE
   # n_bytes := *(p+8)
   movq -8(%rbp), %rax                      # %RAX := p
   addq $8, %rax                            # %RAX := p + 8
   movq (%rax), %rbx                        # %RBX := *(p + 8)
   movq %rbx, -24(%rbp)                     # num_bytes := *(p + 8)
   # for (i = 0; i < 15; ++i)
   #    printf("#"); 
   movq $0, -16(%rbp)                       # i := 0
for_hash:
   movq -16(%rbp), %rax                     # %RAX := i
   movq $15, %rbx                           # %RBX := 15
   cmpq %rbx, %rax                          # COMPARA i e 15
   jge fora_for_hash                        # SE i >= 15, SAI DO FOR

   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_HASH, %rdi                     # %RDI := "#"
   call printf                              # IMPRIME "#" NA TELA

   movq -16(%rbp), %rax                     # %RAX := i
   addq $1, %rax                            # %RAX := i + 1
   movq %rax, -16(%rbp)                     # i := i + 1
   jmp for_hash                             # VOLTA INÍCIO DO FOR_HASH
fora_for_hash:
   # -if ( *p == 0 ) -> Bloco LIVRE
   #    ...
   # -else
   #    ...
   movq -8(%rbp), %rax                      # %RAX := p
   movq (%rax), %rax                        # %RAX := *p
   movq $0, %rbx                            # %RBX := 0
   cmpq %rbx, %rax                          # COMPARA *p e 0
   jne else_livre                           # SE *p != 0, PULA PARA O ELSE
   # for (i = 0; i < n_bytes; ++i)
   #    printf("-");                
   movq $0, -16(%rbp)                       # i := 0
for_menos:                      
   movq -16(%rbp), %rax                     # %RAX := i
   movq -24(%rbp), %rbx                     # %RBX := n_bytes
   cmpq %rbx, %rax                          # COMPARA i e n_bytes
   jge fora_if_livre                        # SE i >= n_bytes, SAI DO FOR

   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_MENOS, %rdi                    # %RDI := "-"
   call printf                              # IMPRIME "-" NA TELA

   movq -16(%rbp), %rax                     # %RAX := i
   addq $1, %rax                            # %RAX := i + 1
   movq %rax, -16(%rbp)                     # i := i + 1
   jmp for_menos                            # VOLTA INÍCIO DO FOR_MENOS
else_livre:
   # for (i = 0; i < n_bytes; ++i)
   #    printf("+");
   movq $0, -16(%rbp)                       # i := 0                        
for_mais:
   movq -16(%rbp), %rax                     # %RAX := i
   movq -24(%rbp), %rbx                     # %RBX := n_bytes
   cmpq %rbx, %rax                          # COMPARA i e n_bytes
   jge fora_if_livre                        # SE i >= n_bytes, SAI DO FOR

   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_MAIS, %rdi                     # %RDI := "+"
   call printf                              # IMPRIME "-" NA TELA

   movq -16(%rbp), %rax                     # %RAX := i
   addq $1, %rax                            # %RAX := i + 1
   movq %rax, -16(%rbp)                     # i := i + 1
   jmp for_mais                             # VOLTA INÍCIO DO FOR_MAIS
fora_if_livre:
   # printf("\n");
   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_NOVA_LINHA, %rdi    
   call printf
   # p += n_bytes + 16
   movq -24(%rbp), %rax                     # %RAX := n_bytes
   movq -8(%rbp), %rbx                      # %RBX := p
   addq $16, %rax                           # %RAX := n_bytes + 16
   addq %rax, %rbx                          # %RBX := p + n_bytes + 16
   movq %rbx, -8(%rbp)                      # p := p + n_bytes + 16
   jmp while_imprime_heap                   # VOLTA PARA INÍCIO DO WHILE_IMPRIME                       
fora_while_imprime_heap:
   # printf("\n");
   movq $0, %rdi                            # %RDI := NULL
   call fflush                              # LIMPA BUFFER DE IMPRESSÃO
   movq $STR_NOVA_LINHA, %rdi    
   call printf

   # - - - - - - - - - - - - - -
   # Fim da Função              
   addq $24, %rsp                  
   popq %rbp                       
   ret
