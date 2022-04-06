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
.equ INCREMENT_LENGTH,  4112

.PointerMask:
    .string "%p\n"

.IntegerMask:
    .string "%ld\n"

.StringMask:
    .string "%s\n"

.StartString:
    .string "Start\n"

.BlockMask:
    .string " %ld | %ld |  %ld | "

.BreakLine:
    .string "\n"

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

    movq    $.StartString, %rdi
    movq    $0, %rax
    call    printf

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


imprimeBlocos:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    INICIO, %r11

    PRINT_START:
    cmpq    FIM, %r11
    jge     PRINT_END

    # store r11

    pushq   %r11
    
    movq    %r11, %rcx
    movq    STATUS_LENGTH(%r11), %rdx
    movq    (%r11), %rsi
    movq    $.BlockMask, %rdi
    movq    $0, %rax
    call    printf

    popq    %r11

    # retrieve r11

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


/* Este procedimento funde os blocos livres conectados em um bloco unico */
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
    cmpq    FIM, %r9
    jge     MERGE_END
    cmpq    FIM, %r10
    jge     MERGE_END

    # Ve se o bloco atual e o próximo estão livres
    TRY_TO_MERGE:
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
    addq    $STATUS_LENGTH, %r10
    addq    $SIZE_LENGTH, %r10
    addq    STATUS_LENGTH(%r10), %r10

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


/* Imprime os endereços do começo e do fim do domínio */
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


/* Escreve free na label indicada pelo parâmetro */
# liberaMem(long int)
liberaMem:
    pushq   %rbp
    movq    %rsp, %rbp

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
    movq    %rdi, %rcx

    # Determina em qual bloco começa a procura por espaço
    movq    INICIO, %rdx

    # Determina o limite de onde procurar
    /*
    %r10 delimita a memória que ainda pode ser alocada,
    Caso (%rdx > FIM - STATUS_L - SIZE_L - 1) não há como alocar memoria neste espaço
    Então o FIM terá de ser expandido
    */
    movq    $FREE_LABEL, %rbx

    ALLOC_UPDATE_LIMIT:
    movq    FIM, %r10
    subq    $STATUS_LENGTH, %r10
    subq    $SIZE_LENGTH, %r10
    subq    $1, %r10
    
    ALLOC_START_WHILE:
    # Testa se o bloco está livre
    cmpq    (%rdx), %rbx
    jne     ALLOC_NOT_FREE
    # Testa se há espaço o suficiente
    cmpq    %rcx, STATUS_LENGTH(%rdx)
    jge     ALLOC_FOUND_FREE_SPACE

    # Caso o bloco atual não esteja livre ou não haja espaço o suficiente, vai para o próximo bloco
    ALLOC_NOT_FREE:
    movq    STATUS_LENGTH(%rdx), %r8
    addq    $STATUS_LENGTH, %rdx
    addq    $SIZE_LENGTH, %rdx
    addq    %r8, %rdx

    # Verifica se o próximo bloco a ser analisado está dentro dos limites do domínio, do contrário o domínio deve ser expandido
    cmpq    %r10, %rdx
    jge     ALLOC_EXPAND_DOMAIN
    jmp     ALLOC_START_WHILE

    ALLOC_EXPAND_DOMAIN:
    call    expandDomain
    movq    $FREE_LABEL, (%rdx)
    movq    $CHUNK_LENGTH, STATUS_LENGTH(%rdx)
    call    mergeBlocks
    jmp     ALLOC_UPDATE_LIMIT

    ALLOC_FOUND_FREE_SPACE:
    /* Caso o espaços disponivel seja maior que o requerido, reparte o espaço*/

    # Calcula o novo tamanho do bloco restante
    movq    STATUS_LENGTH(%rdx), %r8
    subq    %rcx, %r8
    subq    $STATUS_LENGTH, %r8
    subq    $SIZE_LENGTH, %r8

    # Caso não haja espaço restante não separa o bloco
    movq    $0, %rbx
    cmpq    %rbx, %r8
    jle     ALLOC_END
    movq    %rdx, %r9
    addq    $STATUS_LENGTH, %r9
    addq    $SIZE_LENGTH, %r9
    addq    %rcx, %r9
    movq    $FREE_LABEL, (%r9)
    movq    %r8, STATUS_LENGTH(%r9)

    ALLOC_END:
    movq    $OCCUPIED_LABEL, (%rdx)
    movq    %rcx, STATUS_LENGTH(%rdx)

    addq    $STATUS_LENGTH, %rdx
    addq    $SIZE_LENGTH, %rdx
    movq    %rdx, %rax

    popq    %rbp
    ret
