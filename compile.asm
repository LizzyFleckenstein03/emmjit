section .text

; in rdi program (reversed)
; in rsi program size
; out rax newfunc ptr
; out rdx newfunc info
; caller-saved: as usual
; callee-saved: may use r12, must not use rbx
compile:

    test rsi, rsi
    jz .empty_prog

    ; r12 newinfo

    mov rbp, rsp
    xor r12, r12

    ; rax temp
    ; rdx copysrc
    ; r11: r11d copylen, bit (1<<32) rewritejmp
    ; r8 info
    ; r9 nextinfo
    ; r10 nextindex
    ; rcx cl char or nextchar; ch removepush

    mov r10, 1                 ; init nextindex
    movzx rcx, byte[rdi+0]     ; init char
    mov r8, [instr_info+8*rcx] ; init info

.l_prep:
    ; init src, len
    movzx rax, cl
    mov rdx, [instr_func+8*rax]
    mov r11, r8
    shr r11, 32

.l_prep_check_head:
    ; check if head
    cmp r10, rsi
    jne .l_prep_headopt

    ; copy head flags
    mov rax, r8
    and rax, FLAG_GETTOP|FLAG_POP
    or r12, rax

    ; don't run headopt
    jmp .l_prep_check_tail

.l_prep_headopt:
    ; load nextinfo
    mov cl, [rdi+r10]
    movzx rax, cl
    mov r9, [instr_info+8*rax]

    ; gettop can be removed if preceded by settop or push
    test r8, FLAG_GETTOP
    jz .l_prep_headopt_pop
    test r9, FLAG_SETTOP|FLAG_PUSH
    jz .l_prep_headopt_pop

    ; remove gettop
    add rdx, SIZE_STACK_GETTOP
    sub r11, SIZE_STACK_GETTOP

    jmp .l_prep_check_tail

.l_prep_headopt_pop:
    ; next for current pop and pred push
    test r8, FLAG_POP
    jz .l_prep_check_tail
    test r9, FLAG_PUSH
    jz .l_prep_check_tail

    ; remove pop
    add rdx, SIZE_STACK_POP
    sub r11, SIZE_STACK_POP

    ; and remember to remove push
    or ch, (1<<1)

.l_prep_check_tail:
    ; check if tail
    cmp r10, 1
    jne .l_prep_tailopt

    ; copy tail flags
    mov rax, r8
    and rax, FLAG_JMP|FLAG_SETTOP|FLAG_PUSH
    or r12, rax

    ; dont run tailopt
    jmp .l_prep_next
.l_prep_tailopt:
    test r8, FLAG_JMP
    jz .l_prep_tailopt_push

    ; set rewritejmp flag
    mov rax, (1<<32)
    or r11, rax

    jmp .l_prep_next
.l_prep_tailopt_push:
    test ch, 1
    jz .l_prep_tailopt_ret

    ; remove push
    sub r11, SIZE_STACK_PUSH

.l_prep_tailopt_ret:
    ; remove ret
    sub r11, SIZE_RET

.l_prep_next:
    push rdx ; src
    push r11 ; len + flag

    ; increase alloc size
    shl r11, 32
    add r12, r11
%if SAFETY
    ; check for overflow
    SAFETY_ASSERT safety_func_size, jnc
%endif

    ; exit condition
    cmp r10, rsi
    je .alloc

    ; next
    inc r10
    shr ch, 1
    mov r8, r9
    jmp .l_prep

.alloc:
    mov rdi, r12
    shr rdi, 32
    call heap_new

    ; moving ptr
    mov rdi, rax

    ; rewritejmp bit
    mov r8, 1 << 32

.l_copy:
    pop rdx ; len + flag
    pop rsi ; src
    mov ecx, edx ; len
    ; copy code
    rep movsb
    ; exit if done
    cmp rbp, rsp
    je .finish
    ; check for rewritejmp bit
    test rdx, r8
    jz .l_copy
%if SAFETY
    ; verify start of jmp instruction
    cmp word[rdi-SIZE_JMP], 0x24ff
    SAFETY_ASSERT safety_invalid_jmp, je
%endif
    ; rewrite jmp to call
    mov byte[rdi-SIZE_JMP+1], 0x14
    jmp .l_copy

.finish:
    mov rdx, r12
    ret

.empty_prog:
    ; make nop
    mov rdi, 1
    call heap_new
    mov byte[rax], 0xc3
    mov rdx, 1 << 32
    ret
