section .text

op_nop:
    .tail: ret
    .end: int3

op_pushzero:
    STACK_PREPUSH
    dec STACK
    mov byte[STACK], 0
    .tail: ret
    .end: int3

op_add:
    STACK_PREPOP
    mov al, [STACK]
    inc STACK
    STACK_PREPOP
    add [STACK], al 
    .tail: ret
    .end: int3

op_sub:
    STACK_PREPOP
    mov al, [STACK]
    inc STACK
    STACK_PREPOP
    sub [STACK], al 
    .tail: ret
    .end: int3

op_log:
    STACK_PREPOP
    movzx ax, byte[STACK]
    lzcnt ax, ax
    mov cx, 7
    cmovc ax, cx
    mov cl, 16
    sub cl, al
    mov [STACK], cl
    .tail: ret
    .end: int3

op_output:
    STACK_PREPOP
    movzx rdi, byte[STACK]
    inc STACK
    .tail: jmp [fptr.io_putchar]
    .end: int3

op_input:
    call [fptr.io_getchar]
    STACK_PREPUSH
    dec STACK
    mov [STACK], al
    .tail: ret
    .end: int3

op_enqueue:
    STACK_PREPOP
    mov al, [STACK]
    mov [QUEUE_W], al
    inc QUEUE_W
    and QUEUE_W, ~((~0)<<QUEUE_BITS)
%if SAFETY
    cmp QUEUE_R, QUEUE_W
    SAFETY_ASSERT safety_queue_overflow
%endif
    .tail: ret
    .end: int3

op_dequeue:
%if SAFETY
    cmp QUEUE_R, QUEUE_W
    SAFETY_ASSERT safety_queue_underflow
%endif
    mov al, [QUEUE_R]
    inc QUEUE_R
    and QUEUE_R, ~((~0)<<QUEUE_BITS)
    STACK_PREPUSH
    dec STACK
    mov byte[STACK], al
    .tail: ret
    .end: int3

op_dup:
    STACK_PREPOP
    mov al, [STACK]
    STACK_PREPUSH
    dec STACK
    mov [STACK], al
    .tail: ret
    .end: int3

op_exec:
    STACK_PREPOP
    movzx rax, byte[STACK]
    inc STACK
    .tail: jmp [instr_func+rax*8]
    .end:

op_pushsep:
    STACK_PREPUSH
    dec STACK
    mov byte[STACK], ';'
    .tail: ret
    .end: int3
