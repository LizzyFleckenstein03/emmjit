section .text

%macro SAFETY_ASSERT 1-2 jnz
    %2 $+2+7+1
    int1
    call [fptr.%1]
%endmacro

%macro STACK_PREPUSH 0
%if SAFETY
    cmp STACK, stack
    SAFETY_ASSERT safety_stack_overflow
%endif
%endmacro

%macro STACK_PREPOP 0
%if SAFETY
    cmp STACK, stack.end
    SAFETY_ASSERT safety_stack_underflow
%endif
%endmacro

safety_stack_overflow:
    mov rdi, .msg
    jmp io_error
.msg: db "stack overflow",10,0

safety_stack_underflow:
    mov rdi, .msg
    jmp io_error
.msg: db "stack underflow",10,0

safety_queue_overflow:
    mov rdi, .msg
    jmp io_error
.msg: db "queue overflow",10,0

safety_queue_underflow:
    mov rdi, .msg
    jmp io_error
.msg: db "queue underflow",10,0

safety_invalid_jmp:
    mov rdi, .msg
    jmp io_error
.msg: db "unsupported jump instruction while compiling",10,0
