/*
Domínio: a parte da heap que estamos operando sobre, começa em INICIO e termina em FIM.
Aumentar FIM significa aumentar o domínio.

Retorno de funções: todos os retornos serão escritos em %rax
*/

.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
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
.equ INCREMENT_LENGTH,  5012

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

    /* param == 0 ? param = param + brk(0) : pass */
    movq    $0, %rdx
    cmpq    %rdi, %rdx
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


expandDomain:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $INCREMENT_LENGTH, %rdi
    call    brk
    movq    %rax, FIM

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
    movq    $0, %rdi
    call    brk
    movq    %rax, INICIO

    movq    $INCREMENT_LENGTH, %rdi
    call    brk
    movq    %rax, FIM

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
printDomain:
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

    movq    %rdi, %rcx
    subq    $STATUS_LENGTH, %rcx
    subq    $SIZE_LENGTH, %rcx
    movq    $FREE_LABEL, (%rcx)
    
    popq    %rbp
    ret


# alocaMem(long int)
alocaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    # Recupera o parâmetro
    movq    %rdi, %rcx

    # Determina onde começa a procura
    movq    INICIO, %rdx

    # Determina o limite de onde procurar
    /*
    %r10 delimita a memória que ainda pode ser alocada,
    Caso (%rdx > FIM - STATUS_L - SIZE_L - 1) não há como alocar memoria neste espaço
    Então o FIM terá de ser expandido
    */
    movq    $FREE_LABEL, %rbx

    UPDATE_LIMIT:
    movq    FIM, %r10
    subq    $STATUS_LENGTH, %r10
    subq    $SIZE_LENGTH, %r10
    subq    $1, %r10
    
    START_WHILE:
    # Testa se o bloco está livre
    cmpq    (%rdx), %rbx
    jne     NOT_FREE
    # Testa se há espaço o suficiente
    cmpq    %rcx, STATUS_LENGTH(%rdx)
    jge     FOUND_FREE_SPACE

    NOT_FREE:
    movq    STATUS_LENGTH(%rdx), %r8
    addq    $STATUS_LENGTH, %rdx
    addq    $SIZE_LENGTH, %rdx
    addq    %r8, %rdx

    cmpq    %r10, %rdx
    jg      EXPAND_DOMAIN
    jmp     START_WHILE

    EXPAND_DOMAIN:
    call    expandDomain
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
    cmpq    %rbx, %r8
    jle     END
    movq    %rdx, %r9
    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9
    addq    %rcx, %r9
    movq    $FREE_LABEL, (%r9)
    movq    %r8, STATUS_LENGTH(%r9)

    END:
    movq    $OCCUPIED_LABEL, (%rdx)
    movq    %rcx, STATUS_LENGTH(%rdx)

    addq    $STATUS_LENGTH, %rdx
    addq    $SIZE_LENGTH, %rdx
    movq    %rdx, %rax

    popq    %rbp
    ret
