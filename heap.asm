section .text

; todo: replace this by a less bogus implementation

heap_alloc:
    mov rsi, rdi ; length
    IO_PAGEALIGN rsi
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

heap_free:
    IO_PAGEALIGN rsi
    ; addr in rdi
    mov rax, SYS_munmap
    syscall
    ret
