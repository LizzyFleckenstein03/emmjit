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
    xor rdi, rdi
    ; loop to collect func info
    .l_prepare:
        STACK_PREPOP
        inc STACK
        ; get current symbol
        movzx rax, byte[STACK-1]
        ; check terminator
        cmp al, ';'
        je .l_prepare_end
        ; func ptr
        mov rsi, [instr_func+rax*8]
        ; alloc size
        lea rax, [rax*2]
        mov rcx, [instr_info+rax*8]
        ; ret-tail size
        xor r8, r8
        ; tail offset
        mov r12, [instr_info+rax*8+8]
        ; check if tail is ret
        mov al, [rsi+r12]
        cmp al, 0xc3
        ; remove tail-ret byte
        mov r9, 1
        cmove r8, r9
        sub rcx, r8
        ; next
        push r12 ; tail
        push rsi  ; src
        push rdi ; dst offset
        push rcx ; size
        add r12, rdi ; newfunc tail offset
        add rdi, rcx ; add to allocation
        jmp .l_prepare
    .l_prepare_end:
        cmp rsp, rbp
        je .empty_func       
            
        ; add back removed ret-tail
        add [rsp], r8
        add rdi, r8

    ; allocate memory
    push rdi
    call [fptr.heap_alloc]
    pop r8

    ; variables:
    ; rax = newfunc ptr
    ; r8 = newfunc size
    ; r12 = newfunc tail offset

    xor r8, r8
    .l_copy:
        pop rcx ; size
        pop rdi ; dst offset
        pop rsi ; src
        pop r9  ; tail
        ; add newfunc to offset
        add rdi, rax
        ; copy
        push rdi
        rep movsb
        pop rdi
        ; check if done
        cmp rbp, rsp
        je .finish
        ; if not last, rewrite jmp to call
        ; check if jmp
        cmp byte[rdi+r9], 0xff
        jne .l_copy
%if SAFETY
        cmp word[rdi+r9+1], 0x2524
        SAFETY_ASSERT safety_invalid_jmp, jz
%endif
        ; change jmp to call
        mov byte[rdi+r9+1], 0x14
        jmp .l_copy

.empty_func:
    ; make nop function
    mov rdi, 1
    call [fptr.heap_alloc]
    mov byte[rax], 0xc3 ; write ret
    mov r8, 1
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
    mov [instr_info+rax*8], r8
    ; total tail ptr
    mov [instr_info+rax*8+8], r12
    ; skip heap free if same as init
    cmp rdi, [instr_func_init+rbx*8]
    jne .tail
    call [fptr.heap_free]
    .tail: ret
    .end: int3
