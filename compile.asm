section .text

; note: this uses rbx and r12 as callee-saved registers
op_compile:
    ; base ptr
    push rbp
    mov rbp, rsp
    ; symbol to define
    STACK_PREPOP
    movzx rbx, byte[STACK]
    inc STACK
    ; allocation size
    xor r12, r12
    ; loop to collect func info
.l_prep:
        STACK_PREPOP
        inc STACK
        ; get current symbol
        movzx rax, byte[STACK-1]
        ; check terminator
        cmp al, ';'
        je .alloc
        ; func ptr
        mov rsi, [instr_func+rax*8]
        ; size
        lea rax, [rax*2]
        mov rcx, [instr_info+rax*8]
        ; tail offset
        mov rdx, [instr_info+rax*8+8]
        ; skip ret-tail removal for last op
        cmp rsp, rbp
        je .l_prep_next
        ; check if tail is ret
        cmp byte[rsi+rdx], 0xc3
        jne .l_prep_next
        ; remove ret-tail byte
        dec rcx
.l_prep_next:
        add r12, rcx ; add to allocation
        push rdx ; tail
        push rsi ; src
        push rcx ; size
        jmp .l_prep

.alloc:
    ; special case for empty funcs
    cmp rsp, rbp
    je .empty_func
    ; allocate memory
    mov rdi, r12
    call [fptr.heap_alloc]
    ; moving pointer
    mov rdi, rax

.l_copy:
        pop rcx ; size
        pop rsi ; src
        pop rdx ; tail
        mov r8, rdi ; backup current ptr
        ; copy code
        rep movsb
        ; check if done
        cmp rbp, rsp
        jne .l_copy_rewrite
        ; total tail offset = item_ptr+tail-func_ptr
        lea r11, [r8+rdx]
        sub r11, rax
        ; done
        jmp .finish
.l_copy_rewrite:
        ; check if jmp
        cmp byte[r8+rdx], 0xff
        jne .l_copy
%if SAFETY
        ; check the byte we're changing, to be sure
        cmp byte[r8+rdx+1], 0x24
        SAFETY_ASSERT safety_invalid_jmp, jz
%endif
        ; rewrite jmp to call
        mov byte[r8+rdx+1], 0x14
        ; continue
        jmp .l_copy

.empty_func:
    ; make nop function
    mov rdi, 1
    call [fptr.heap_alloc]
    mov byte[rax], 0xc3 ; write ret
    mov r11, 1
    mov r12, 0

.finish:
    ; restore base ptr
    pop rbp
    ; load old ptr into arg1
    mov rdi, [instr_func+rbx*8]
    ; store new ptr
    mov [instr_func+rbx*8], rax
    ; load old size into arg2
    lea rax, [rbx*2]
    mov rsi, [instr_info+rax*8]
    ; store new info
    mov [instr_info+rax*8], r12
    ; total tail ptr
    mov [instr_info+rax*8+8], r11
    ; skip heap free if same as init
    cmp rdi, [instr_func_init+rbx*8]
    jne .tail
    call [fptr.heap_free]
    .tail: ret
    .end: int3
