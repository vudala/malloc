/*
Domínio: a parte da heap que estamos operando sobre, começa em INICIO e termina em FIM.
Aumentar FIM significa aumentar o domínio.

Retorno de funções: todos os retornos serão escritos em %rax
*/



.globl _start

.section .data
INICIO: .quad   0
FIM:    .quad   0

# Constantes
.equ FREE_LABEL,        0
.equ OCCUPIED_LABEL,    1
.equ STATUS_LENGTH,     8
.equ SIZE_LENGTH,       8
.equ CHUNK_LENGTH,      4096
.equ TOTAL_LENGTH,      5012

.PointerMask:
    .string "%p\n"

.IntegerMask:
    .string "%ld\n"

.StringMask:
    .string "%s\n"

.StartString:
    .string "Start\n"

.section .text

# brk(long int)
brk:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    16(%rbp), %rcx

    /* param == 0 ? param = param + brk(0) : pass */
    movq    $0, %rdx
    cmpq    %rcx, %rdx
    je      EQUAL_ZERO
    pushq   %rcx
    pushq   $0
    call    brk
    addq    $8, %rsp
    popq    %rcx
    addq    %rax, %rcx

    EQUAL_ZERO:
    movq    %rcx, %rdi
    movq    $12, %rax
    syscall

    popq    %rbp
    ret


iniciaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    /* Chama printf caso seja a primeira vez que a função é invocada */
    movq    $0, %rbx
    cmpq    %rbx, INICIO
    jne     ALREADY_STARTED
    movq    $.StartString, %rdi
    call    printf

    ALREADY_STARTED:
    pushq   $0
    call    brk
    movq    %rax, INICIO
    addq    $8, %rsp

    pushq   $TOTAL_LENGTH
    call    brk
    movq    %rax, FIM
    addq    $8, %rsp

    movq    INICIO, %rsi
    movq    $FREE_LABEL, (%rsi)
    movq    $CHUNK_LENGTH, STATUS_LENGTH(%rsi)

    popq    %rbp
    ret


/* Restaura brk para o valor inicial, redefine FIM*/
finalizaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $12, %rax
    movq    INICIO, %rdi
    syscall
    movq    %rax, FIM

    popq    %rbp
    ret


/* Imprime o começo e o fim do domínio */
imprimeDominioHeap:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    INICIO, %rsi
    movq    $.PointerMask, %rdi
    movq    $0, %rax
    call    printf

    movq    FIM, %rsi
    movq    $.PointerMask, %rdi
    movq    $0, %rax
    call    printf

    popq    %rbp
    ret


/* Escreve free na label indicada pelo parâmetro */
# liberaMem(long int)
liberaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    16(%rbp), %rcx
    movq    $FREE_LABEL, (%rcx)
    
    popq    %rbp
    ret


# alocaMem(long int)
alocaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    # Recupera o parâmetro e adiciona o tamanho do cabeçalho
    movq    16(%rbp), %rcx

    # Determina onde começa a procura
    movq    INICIO, %rdx

    # Determina o limite de onde procurar
    /*
    %r10 delimita a memória que ainda pode ser alocadaa,
    Caso (%rdx > FIM - STATUS_L - SIZE_L - 1) não há como alocar memoria neste espaço
    Então o FIM terá de ser expandido
    */

    UPDATE_LIMIT:
    movq    FIM, %r10
    subq    $STATUS_LENGTH, %r10
    subq    $SIZE_LENGTH, %r10
    subq    $1, %r10

    # Testa se o bloco está livre
    movq    $FREE_LABEL, %rbx
    START_WHILE:
    cmpq    (%rdx), %rbx
    jne      SKIP
    # Testa se há espaço o suficiente
    cmpq    %rcx, STATUS_LENGTH(%rdx)
    jge     FOUND_FREE_SPACE

    SKIP:
    movq    STATUS_LENGTH(%rdx), %r8
    addq    $STATUS_LENGTH, %rdx
    addq    $SIZE_LENGTH, %rdx
    addq    %r8, %rdx

    cmpq    %rdx, %r10
    jg      INCREASE_MEMORY_DOMAIN
    jmp     START_WHILE

    INCREASE_MEMORY_DOMAIN:
    pushq   $TOTAL_LENGTH
    call    brk
    addq    $8, %rsp
    movq    %rax, FIM
    jmp     UPDATE_LIMIT

    FOUND_FREE_SPACE:
    /* Caso o espaços disponivel seja maior que o requerido, reparte o espaço*/

    # Calcula o novo tamanho do bloco restante
    movq    STATUS_LENGTH(%rdx), %r8
    subq    %rcx, %r8
    subq    $STATUS_LENGTH, %r8
    subq    $SIZE_LENGTH, %r8
    # Caso não haja espaço restante não separa o bloco
    movq    $0, %rbx
    cmpq    %r8, %rbx
    jle     END
    movq    %rdx, %r9
    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9
    addq    %rcx, %r9
    movq    $FREE_LABEL, %r9
    movq    %r8, STATUS_LENGTH(%r9)

    END:
    movq    $OCCUPIED_LABEL, (%rdx)
    movq    %rcx, STATUS_LENGTH(%rdx)

    popq    %rbp
    ret


_start:
    call    iniciaAlocador

    call    imprimeDominioHeap

    pushq   $100
    call    alocaMem
    addq    $8, %rsp
    
    call    finalizaAlocador
    
    movq    $60, %rax
    syscall
