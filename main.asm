global _start, instr_func, instr_info

%define STACK r13
%define QUEUE_W r14
%define QUEUE_R r15

%define STACK_BITS 29 ; 512MiB
%define QUEUE_BITS 24 ; 16MiB

%define SAFETY 0

section .bss

stack: resb (1<<STACK_BITS)
.end:
queue: resb (1<<QUEUE_BITS)

section .text

%include "const.asm"
%include "io.asm"
%include "heap.asm"

section .data

fptr:
    .io_putchar: dq io_putchar
    .io_getchar: dq io_getchar
    .heap_alloc: dq heap_alloc
    .heap_free: dq heap_free
    .safety_stack_overflow: dq safety_stack_overflow
    .safety_stack_underflow: dq safety_stack_underflow
    .safety_queue_overflow: dq safety_queue_overflow
    .safety_queue_underflow: dq safety_queue_underflow
    .safety_invalid_jmp: dq safety_invalid_jmp

section .text

_start:
    ; argc
    mov rcx, [rsp]
    cmp rcx, 2
    jl .argc_err
    
    ; argv[1]
    mov rdi, [rsp+8+8]
    
    call io_map_file
    mov rbx, rax ; pointer
    mov r12, rdx ; size

    ; rdi = r12*7+1
    lea rdi, [r12*2+r12]
    lea rdi, [rdi*2+r12+1]
    push rdi
    call heap_alloc
    mov r9, rax ; newfunc

    ; loop counter
    xor rcx, rcx

.l_compile:
    cmp rcx, r12
    je .l_compile_end

    ; write call
    ; ff 14 25 xx xx xx xx

    mov dword[rax], 0x2514ff

    movzx rdx, byte[rbx+rcx]
    lea rdx, [instr_func+rdx*8]
    mov dword[rax+3], edx

    add rax, 7
    inc rcx
    jmp .l_compile

.l_compile_end:
    ; write ret
    mov byte[rax], 0xc3

    ; set up storage
    mov STACK, stack.end
    xor QUEUE_W, QUEUE_W
    xor QUEUE_R, QUEUE_R

    ; execute code
    call r9

    ; done!
    jmp io_exit

.argc_err:
    mov rdi, .argc_err_msg
    jmp io_error

.argc_err_msg: db "not enough arguments",10,0

%include "safety.asm"
%include "ops.asm"
%include "compile.asm"
%include "gen.asm"
