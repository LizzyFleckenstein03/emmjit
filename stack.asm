%if SAFETY

%macro STACK_PREPUSH 0
    cmp STACK, stack
    SAFETY_ASSERT safety_stack_overflow
%endmacro
%define SIZE_STACK_PREPUSH 7+SIZE_SAFETY_ASSERT

%macro STACK_PREPOP 0
    cmp STACK, stack.end
    SAFETY_ASSERT safety_stack_underflow
%endmacro
%define SIZE_STACK_PREPOP 7+SIZE_SAFETY_ASSERT

%else ; no SAFETY

%macro STACK_PREPUSH 0
%endmacro
%define SIZE_STACK_PREPUSH 0

%macro STACK_PREPOP 0
%endmacro
%define SIZE_STACK_PREPOP 0

%endif ; SAFETY

%macro STACK_SETTOP 0
    mov [STACK], al
%endmacro
%define SIZE_STACK_SETTOP 4

%macro STACK_PUSH 0
    STACK_PREPUSH
    dec STACK
    STACK_SETTOP
%endmacro
%define SIZE_STACK_PUSH SIZE_STACK_PREPUSH+3+SIZE_STACK_SETTOP

%macro STACK_GETTOP 0
    STACK_PREPOP
    mov al, [STACK]
%endmacro
%define SIZE_STACK_GETTOP SIZE_STACK_PREPOP+4

%macro STACK_POP 0
    STACK_GETTOP
    inc STACK
%endmacro
%define SIZE_STACK_POP SIZE_STACK_GETTOP+3
