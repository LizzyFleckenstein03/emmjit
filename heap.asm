section .data

heap_freelist: dq 0
heap_last_growsize: dq 0

heap_num_blocks: dq 0

; heap block:
; -8 size
; +0 prev
; +8 next

section .text

; map a new page
heap_mmap:
    mov rsi, rdi ; length
    mov rdi, 0 ; addr
    mov rdx, PROT_READ|PROT_WRITE|PROT_EXEC ; prot
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS ; flags
    mov r8, 0 ; fd
    mov r9, 0 ; offset
    mov rax, SYS_mmap
    syscall
    cmp rax, 0
    jl .err
    ret
.err:
    mov rdi, .err_msg
    jmp io_error
.err_msg: db "heap allocation failure",10,0


; get new memory from kernel
heap_grow:
    add rdi, 24
    IO_PAGEALIGN rdi

    mov rax, [heap_last_growsize]

    cmp rdi, rax
    cmovb rdi, rax

    shl rdi, 1 ; mul by 2

    mov [heap_last_growsize], rdi

    call heap_mmap

    mov rcx, [heap_last_growsize]

    sub rcx, 8
    mov [rax], rcx

    lea rdi, [rax+8]
    call heap_free

    ret

; merge adjacent blocks
heap_defrag:
    mov rax, [heap_num_blocks]
    test rax, rax
    jz .done

    ; todo: qsort and merge

.done:
    ret


; allocate but fail if no memory in current freelist
heap_try_alloc:
    mov rax, [heap_freelist]

    test rax, rax
    jz .fail

    ; original
    mov rdx, rax

.find:
    mov rcx, [rax-8] ; load size
    cmp rcx, rdi
    jae .found

    mov rax, [rax+8] ; next
    cmp rax, rdx
    jne .find

.fail:
    xor rax, rax
    ret

.found:
    lea rdx, [rdi+24]
    cmp rcx, rdx
    jae .split

    dec qword[heap_num_blocks]

    mov r8, [rax+0] ; prev
    mov r9, [rax+8] ; next

    ; block is its own predecessor
    cmp r8, rax
    je .lastblk

    mov [r8+8], r9 ; prev->next = next
    mov [r9+0], r8 ; next->prev = prev

    mov [heap_freelist], r8
    ret

.split:
    mov [heap_freelist], rax

    ; space occupied by splitoff blk
    lea rdx, [rdi+8]

    ; update leftover blk
    sub rcx, rdx
    mov [rax-8], rcx

    ; splitoff blk
    lea rax, [rax+rcx+8]
    mov [rax-8], rdi
    ret

.lastblk:
    mov qword[heap_freelist], 0
    ret


; allocate bytes
heap_alloc:
    ; minimum allocation is 16 bytes
    mov rax, 16
    cmp rdi, 16
    cmovb rdi, rax

    push rdi

    call heap_try_alloc
    test rax, rax
    jnz .done

    call heap_defrag

    mov rdi, [rsp]
    call heap_try_alloc
    test rax, rax
    jnz .done

    mov rdi, [rsp]
    call heap_grow

    mov rdi, [rsp]
    call heap_try_alloc

.done:
    add rsp, 8
    ret


; free object
heap_free:
    mov rax, [heap_freelist]
    test rax, rax
    jz .firstblk

    ; replace next
    mov rcx, [rax+8]    

    ; prev
    mov [rdi+0], rax 
    mov [rax+8], rdi

    ; next
    mov [rcx+0], rdi
    mov [rdi+8], rcx

.done:
    inc qword[heap_num_blocks]
    ret

.firstblk:
    mov [rdi+0], rdi
    mov [rdi+8], rdi
    mov [heap_freelist], rdi

    jmp .done


; allocate refcounted object
heap_new:
    add rdi, 8
    call heap_alloc
    mov qword[rax], 1 ; refcount
    add rax, 8
    ret


; release refcounted object
heap_release:
    dec qword[rdi-8]
    jnz .done
    sub rdi, 8
    jmp heap_free
.done:
    ret
