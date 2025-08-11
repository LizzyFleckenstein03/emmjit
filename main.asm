global _start

%define SAFETY 1
%define TRACE 1

%define STACK r13
%define QUEUE_W r14
%define QUEUE_R r15

%define STACK_BITS 29 ; 512MiB
%define QUEUE_BITS 24 ; 16MiB

%define SIZE_JMP 7
%define SIZE_RET 1

; start: nop or pop or gettop
%define FLAG_POP (1<<0)
%define FLAG_GETTOP (1<<1)

; end: ret or jmp or push or settop
%define FLAG_JMP (1<<2)
%define FLAG_PUSH (1<<3)
%define FLAG_SETTOP (1<<4)

; additional
%define FLAG_INHERIT_REFCOUNT (1<<5)
%define FLAG_REFCOUNT (1<<6)

section .bss

stack: resb (1<<STACK_BITS)
.end:
queue: resb (1<<QUEUE_BITS)

section .data

fptr:
    .io_putchar: dq io_putchar
    .io_getchar: dq io_getchar
    .heap_release: dq heap_release
    .compile: dq compile
    .safety_stack_overflow: dq safety_stack_overflow
    .safety_stack_underflow: dq safety_stack_underflow
    .safety_queue_overflow: dq safety_queue_overflow
    .safety_queue_underflow: dq safety_queue_underflow
    .safety_func_size: dq safety_func_size
    .safety_invalid_jmp: dq safety_invalid_jmp
    .safety_missing_sep: dq safety_missing_sep

%include "const.asm"
%include "io.asm"
%include "safety.asm"
%include "heap.asm"
%include "stack.asm"
%include "compile.asm"
%include "ops.asm"
%include "gen.asm"

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

    ; ignore newline at end of file
    cmp byte[rbx+r12-1], 10
    jne .alloc
    dec r12

.alloc:
    ; rdi = r12*7+1
    lea rdi, [r12*2+r12]
    lea rdi, [rdi*2+r12+1]
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
