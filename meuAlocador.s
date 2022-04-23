/*
Domínio: a parte da heap que estamos operando sobre, começa em INICIO e termina em FIM.
Aumentar FIM significa aumentar o domínio.

Retorno de funções: todos os retornos serão escritos em %rax
*/

.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
.globl imprimeBlocos
.globl imprimeMapa
.globl _start

.section .data
INICIO: .quad   0
FIM:    .quad   0
CHUNK_SIZE: .quad   300

# Constantes
.equ FREE_LABEL,        0
.equ OCCUPIED_LABEL,    1
.equ STATUS_LENGTH,     8
.equ SIZE_LENGTH,       8

.equ PLUS,      43
.equ MINUS,     45

.CharMask:
    .string "%c"

.PointerMask:
    .string "%p\n"

.IntegerMask:
    .string "%ld\n"

.StringMask:
    .string "%s\n"

.StartString:
    .string "Start\n"

.BlockMask:
    .string "| %ld | %5.ld |  %ld "

.LabelsString:
    .string "###############"

.BreakLine:
    .string "\n"

.section .text


# brk(long int), o parâmetro vem em %rdi
brk:
    pushq   %rbp
    movq    %rsp, %rbp

    # param == 0 ? brk(0) : param + brk(0)
    movq    $0, %r15
    cmpq    %rdi, %r15
    je      EQUAL_ZERO
    pushq   %rdi
    movq    $0, %rdi
    call    brk
    popq    %rdi
    addq    %rax, %rdi

    EQUAL_ZERO:
    movq    $12, %rax
    syscall

    popq    %rbp
    ret


# iniciaAlocador()
iniciaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    # Imprime a string inicial pra setar o buffer do printf
    movq    $.StartString, %rdi
    movq    $0, %rax
    call    printf

    movq    $0, %rdi
    call    brk
    movq    %rax, INICIO

    movq    CHUNK_SIZE, %rdi
    addq    $STATUS_LENGTH, %rdi
    addq    $SIZE_LENGTH, %rdi
    call    brk
    movq    %rax, FIM

    movq    INICIO, %rsi
    movq    $FREE_LABEL, (%rsi)
    movq    CHUNK_SIZE, %rax
    movq    %rax, STATUS_LENGTH(%rsi)

    popq    %rbp
    ret


# Restaura brk para o valor inicial, redefine FIM
finalizaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $12, %rax
    movq    INICIO, %rdi
    syscall
    movq    %rax, FIM

    popq    %rbp
    ret


expandDomain:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    FIM, %rsi

    # Dobra o tamanho da chunk
    movq    CHUNK_SIZE, %rax
    addq    %rax, CHUNK_SIZE

    # Aumenta o domínio
    movq    CHUNK_SIZE, %rdi
    addq    $STATUS_LENGTH, %rdi
    addq    $SIZE_LENGTH, %rdi
    call    brk
    movq    %rax, FIM

    # Escreve LIVRE no novo bloco alocado
    movq    $FREE_LABEL, (%rsi)
    movq    CHUNK_SIZE, %rax
    movq    %rax, STATUS_LENGTH(%rsi)

    popq    %rbp
    ret


imprimeBlocos:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    INICIO, %r11

    PRINT_START:
    cmpq    FIM, %r11
    jge     PRINT_END

    pushq   %r11
    
    movq    %r11, %rcx
    movq    STATUS_LENGTH(%r11), %rdx
    movq    (%r11), %rsi
    movq    $.BlockMask, %rdi
    movq    $0, %rax
    call    printf

    popq    %r11
    
    movq    STATUS_LENGTH(%r11), %r12
    addq    $STATUS_LENGTH, %r11
    addq    $SIZE_LENGTH, %r11
    addq    %r12, %r11

    jmp     PRINT_START

    PRINT_END:

    movq    $.BreakLine, %rdi
    movq    $0, %rax
    call    printf

    popq    %rbp
    ret
    

# imprimeMapa()
imprimeMapa:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    INICIO, %r8

    IMPRIME_START:
    cmpq    FIM, %r8
    je      IMPRIME_END

    # Imprime os bytes gerenciais

    pushq   %r8

    movq    $.LabelsString, %rdi
    movq    $0, %rax
    call    printf

    popq    %r8

    movq    $MINUS, %r12

    movq    $FREE_LABEL, %r15
    cmpq    %r15, (%r8)
    je      MINUS_CHAR
    movq    $PLUS, %r12

    MINUS_CHAR:

    pushq   %r8

    movq    STATUS_LENGTH(%r8), %r10
    movq    $1, %r11

    IMPRIME_LOOP:
    cmpq    %r11, %r10
    jl      IMPRIME_NEXT

    pushq   %r11
    pushq   %r10

    movq    $.CharMask, %rdi
    movq    $0, %rax
    movq    %r12, %rsi
    call    printf

    popq    %r10
    popq    %r11

    addq    $1, %r11

    jmp     IMPRIME_LOOP

    IMPRIME_NEXT:
    movq    $.BreakLine, %rdi
    movq    $0, %rax
    call    printf

    popq    %r8

    movq    STATUS_LENGTH(%r8), %r9
    addq    $STATUS_LENGTH, %r8
    addq    $SIZE_LENGTH, %r8
    addq    %r9, %r8

    jmp     IMPRIME_START

    IMPRIME_END:
    popq    %rbp
    ret


# Este procedimento funde os blocos livres conectados em um bloco unico
mergeBlocks:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $FREE_LABEL, %rbx

    # Determina onde começa o merge, %r9 contém o endereço do bloco atual
    movq    INICIO, %r9

    # Armazena em %r10 o endereço do próximo bloco
    START_WHILE_MERGE:
    movq    %r9, %r10
    addq    $STATUS_LENGTH, %r10
    addq    $SIZE_LENGTH, %r10
    addq    STATUS_LENGTH(%r9), %r10

    # Caso o bloco atual ou o próximo estejam fora do dominio, termina o merge
    TRY_TO_MERGE:
    cmpq    FIM, %r9
    jge     MERGE_END
    cmpq    FIM, %r10
    jge     MERGE_END

    # Ve se o bloco atual e o próximo estão livres
    cmpq    %rbx, (%r9)
    jne     CURRENT_BLOCK_NOT_FREE
    cmpq    %rbx, (%r10)
    jne     NEXT_BLOCK_NOT_FREE

    # Casos estejam livres, adiciona o tamanho do próximo bloco no bloco atual
    MERGE_IT:
    movq    STATUS_LENGTH(%r10), %r11
    addq    %r11, STATUS_LENGTH(%r9)
    addq    $STATUS_LENGTH, STATUS_LENGTH(%r9)
    addq    $SIZE_LENGTH, STATUS_LENGTH(%r9)

    # Reaponta o endereço do próximo bloco
    addq    STATUS_LENGTH(%r10), %r10
    addq    $STATUS_LENGTH, %r10
    addq    $SIZE_LENGTH, %r10

    jmp     TRY_TO_MERGE

    # Caso o bloco atual não esteja livre reaponta o endereço do bloco atual
    CURRENT_BLOCK_NOT_FREE:
    movq    %r10, %r9
    jmp     START_WHILE_MERGE

    # Caso o próximo bloco não esteja livre reaponta o enderço do bloco atual e volta ao começo do laço
    NEXT_BLOCK_NOT_FREE:
    movq    %r10, %r9
    addq    STATUS_LENGTH(%r10), %r9
    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9
    jmp     START_WHILE_MERGE

    MERGE_END:

    popq    %rbp
    ret


# Imprime os endereços do começo e do fim do domínio
printDomain:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    INICIO, %rsi
    movq    $.IntegerMask, %rdi
    movq	$0, %rax
    call    printf

    movq    FIM, %rsi
    movq    $.IntegerMask, %rdi
    movq	$0, %rax
    call    printf

    popq    %rbp
    ret


# Escreve free na label indicada pelo parâmetro, e então tenta fundir os blocos livres
# liberaMem(long int)
liberaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    # Escreve LIVRE no bloco
    movq    %rdi, %rcx
    subq    $STATUS_LENGTH, %rcx
    subq    $SIZE_LENGTH, %rcx
    movq    $FREE_LABEL, (%rcx)

    call    mergeBlocks
    
    popq    %rbp
    ret


# alocaMem(long int)
alocaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    # Recupera o parâmetro
    movq    %rdi, %r8

    # Determina onde inicia a busca
    movq    INICIO, %r9

    START_WHILE:
    # Verifica se o bloco está livre
    movq    $FREE_LABEL, %r15
    cmpq    (%r9), %r15
    jne     BLOCK_NOT_FREE

    # Verifica se há espaço o suficiente
    cmpq    %r8, STATUS_LENGTH(%r9)
    jge     FOUND_FREE_SPACE

    # Aponta para o próximo bloco
    BLOCK_NOT_FREE:
    movq    STATUS_LENGTH(%r9), %r15
    addq    %r15, %r9
    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9

    # Verifica se chegou no fim
    cmpq    %r9, FIM
    jne     START_WHILE
    # Expande o domínio
    call    expandDomain  
    jmp     START_WHILE

    FOUND_FREE_SPACE:
    # Caso o espaços disponivel seja maior que o requerido, reparte o espaço
    # Calcula o novo tamanho do bloco restante
    movq    STATUS_LENGTH(%r9), %r15
    subq    %r8, %r15
    subq    $STATUS_LENGTH, %r15
    subq    $SIZE_LENGTH, %r15

    # Caso não haja espaço restante não separa o bloco
    movq    $0, %r11
    cmpq    %r11, %r15
    jle     ALLOC_DONT_SPLIT

    # Separa o bloco em dois: a primeira parte sendo o espaço requerido e a segunda o espaço restante
    movq    %r9, %r11
    addq    $STATUS_LENGTH, %r11
    addq    $SIZE_LENGTH, %r11
    addq    %r8, %r11
    movq    $FREE_LABEL, (%r11)
    movq    %r15, STATUS_LENGTH(%r11)
    jmp     ALLOC_END

    ALLOC_DONT_SPLIT:
    # Caso não haja espaço o suficiente para separar o bloco em dois, devolve o bloco inteiro
    movq    STATUS_LENGTH(%r9), %r8

    ALLOC_END:
    # Escreve OCUPADO no bloco, e seu novo tamanho
    movq    $OCCUPIED_LABEL, (%r9)
    movq    %r8, STATUS_LENGTH(%r9)

    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9
    movq    %r9, %rax

    popq    %rbp
    ret
