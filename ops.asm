section .text

op_nop:
    ret
.end: int3
%define FLAGS_op_nop 0

op_pushzero:
    xor al, al
    STACK_PUSH
    ret
.end: int3
%define FLAGS_op_pushzero FLAG_PUSH

op_add:
    STACK_POP
    STACK_PREPOP
    add al, [STACK]
    STACK_SETTOP
    ret
.end: int3
%define FLAGS_op_add FLAG_POP | FLAG_SETTOP

op_sub:
    STACK_POP
    STACK_PREPOP
    neg al
    add al, [STACK]
    STACK_SETTOP
    ret
.end: int3
%define FLAGS_op_sub FLAG_POP | FLAG_SETTOP

op_log:
    STACK_GETTOP
    movzx ax, al
    mov cx, 7
    lzcnt ax, ax
    cmovnc cx, ax
    mov al, 15
    sub al, cl
    STACK_SETTOP
    ret
.end: int3
%define FLAGS_op_log FLAG_GETTOP | FLAG_SETTOP

op_output:
    STACK_POP
    mov dil, al
    ; don't jmp because rdi might get overwritten
    call [fptr.io_putchar]
    ret
.end: int3
%define FLAGS_op_output FLAG_POP

op_input:
    call [fptr.io_getchar]
    STACK_PUSH
    ret
.end: int3
%define FLAGS_op_input FLAG_PUSH

op_enqueue:
    STACK_GETTOP
    mov [queue+QUEUE_W], al
    inc QUEUE_W
    and QUEUE_W, ~((~0)<<QUEUE_BITS)
%if SAFETY
    cmp QUEUE_R, QUEUE_W
    SAFETY_ASSERT safety_queue_overflow
%endif
    ret
.end: int3
%define FLAGS_op_enqueue FLAG_GETTOP

op_dequeue:
%if SAFETY
    cmp QUEUE_R, QUEUE_W
    SAFETY_ASSERT safety_queue_underflow
%endif
    mov al, byte[queue+QUEUE_R]
    inc QUEUE_R
    and QUEUE_R, ~((~0)<<QUEUE_BITS)
    STACK_PUSH
    ret
.end: int3
%define FLAGS_op_dequeue FLAG_PUSH

op_dup:
    STACK_GETTOP
    STACK_PUSH
    ret
.end: int3
%define FLAGS_op_dup FLAG_GETTOP | FLAG_PUSH

op_compile:
    ; initial symbol
    STACK_POP
    movzx rbx, al
    ; find separator
    mov rdx, stack.end
    sub rdx, STACK
    mov rcx, rdx
    mov al, ';'
    mov rdi, STACK
    repne scasb
    sub rdx, rcx 
%if SAFETY
    SAFETY_ASSERT safety_missing_sep
%endif
    ; compile args
    mov rdi, STACK
    lea rsi, [rdx-1]
    ; pop program from stack
    add STACK, rdx
    ; compile
    call [fptr.compile]
    ; load old func into arg
    mov rdi, [instr_func+rbx*8]
    ; store new func
    mov [instr_func+rbx*8], rax
    mov [instr_info+rbx*8], rdx
    ; skip heap free for initial ops
    cmp rdi, [instr_func_init+rbx*8]
    je .nofree
    ; free
    call [fptr.heap_release]
.nofree:
    ret
.end: int3
%define FLAGS_op_compile FLAG_POP | FLAG_INHERIT_REFCOUNT

%if TRACE

op_exec:
    STACK_POP
    movzx rax, al
    call [instr_func+rax*8]
    ret
.end: int3
%define FLAGS_op_exec FLAG_POP

%else ; no TRACE

op_exec:
    STACK_POP
    movzx rax, al
    jmp [instr_func+rax*8]
.end: int3
%define FLAGS_op_exec FLAG_POP | FLAG_JMP | FLAG_INHERIT_REFCOUNT

%endif ; TRACE

op_pushsep:
    mov al, ';'
    STACK_PUSH
    ret
.end: int3
%define FLAGS_op_pushsep FLAG_PUSH
