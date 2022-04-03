.globl _start

.section .data
INICIO: .quad   0
FIM:    .quad   0

# Constantes
.equ FREE_LABEL,        0
.equ OCCUPIED_LABEL,    1
.equ STATUS_LENGTH,     8
.equ SIZE_LENGTH,       8
.equ CHUNK_LENGTH,      2048
.equ TOTAL_LENGTH,      2064

.PointerMask:
    .string "%p\n"

.IntegerMask:
    .string "%ld\n"

.StringMask:
    .string "%s\n"

.StartString:
    .string "Start\n"

.section .text


brk:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    16(%rbp), %rcx

    movq    $0, %rdx
    cmpq    %rcx, %rdx
    je      EQUAL_ZERO
    pushq   %rcx
    subq    $8, %rsp
    movq    $0, (%rsp)
    call    brk
    movq    %rax, %rdx
    addq    $8, %rsp
    popq    %rcx
    addq    %rdx, %rcx

    EQUAL_ZERO:
    movq    %rcx, %rdi
    movq    $12, %rax
    syscall

    popq    %rbp
    ret


iniciaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $0, %rbx
    cmpq    %rbx, INICIO
    jne     ALREADY_STARTED
    movq    $.StringMask, %rsi
    movq    $.StartString, %rdi
    movq    $0, %rax
    call    printf

    ALREADY_STARTED:
    subq    $8, %rsp
    movq    $0, (%rsp)
    call    brk
    movq    %rax, INICIO
    addq    $8, %rsp

    subq    $8, %rsp
    movq    $TOTAL_LENGTH, (%rsp)
    call    brk
    movq    %rax, FIM
    addq    $8, %rsp

    movq    INICIO, %rsi
    movq    $FREE_LABEL, (%rsi)
    addq    $STATUS_LENGTH, %rsi
    movq    $CHUNK_LENGTH, (%rsi)

    popq    %rbp
    ret


finalizaAlocador:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $12, %rax
    movq    INICIO, %rdi
    syscall

    movq    %rax, FIM

    popq    %rbp
    ret


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


liberaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    16(%rbp), %rcx
    movq    $FREE_LABEL, (%rcx)
    
    popq    %rbp
    ret


alocaMem:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    16(%rbp), %rcx
    movq    $FREE_LABEL, (%rcx)
    
    popq    %rbp
    ret


_start:
    call    imprimeDominioHeap

    call    iniciaAlocador
    call    imprimeDominioHeap

    call    finalizaAlocador
    call    imprimeDominioHeap

    movq    $60, %rax
    syscall
