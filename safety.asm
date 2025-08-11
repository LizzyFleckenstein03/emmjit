%define SIZE_SAFETY_ASSERT 2+1+7
%macro SAFETY_ASSERT 1-2 jnz
    %2 $+SIZE_SAFETY_ASSERT
    int3
    call [fptr.%1]
%endmacro

%macro SAFETY_COND 2
%1:
    mov rdi, .msg
    jmp io_error
.msg: db %2,10,0
%endmacro

section .text
SAFETY_COND safety_stack_overflow, "stack overflow"
SAFETY_COND safety_stack_underflow, "stack underflow"
SAFETY_COND safety_queue_overflow, "queue overflow"
SAFETY_COND safety_queue_underflow, "queue underflow"
SAFETY_COND safety_invalid_jmp, "unsupported jump instruction while compiling"
SAFETY_COND safety_missing_sep, "missing stack separator while compiling"
SAFETY_COND safety_func_size, "function must not be larger than 4GiB"
