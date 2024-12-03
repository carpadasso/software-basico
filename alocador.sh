# Gera objeto do arquivo principal
gcc -fPIC -c exemplo.c -o exemplo.o

# Gera objeto da biblioteca
as meuAlocador.s -o meuAlocador.o

# Liga o arquivo principal com a biblioteca
ld -o alocador exemplo.o meuAlocador.o -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/crt1.o /lib/x86_64-linux-gnu/crti.o /lib/x86_64-linux-gnu/crtn.o -lc

# Executa o programa
./alocador
