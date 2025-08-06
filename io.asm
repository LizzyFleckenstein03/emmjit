section .bss

char_buffer: resb 1
stat_buffer: resb STAT_SIZE

section .text

io_strlen:
    mov rcx, -1
    xor al, al
    repne scasb
    mov rax, -2
    sub rax, rcx
    ret

io_eprint:
    push rdi
    call io_strlen
    pop rsi
    mov rdx, rax
    mov rdi, STDERR_FILENO
    mov rax, SYS_write
    syscall
    ret

io_error:
    call io_eprint
    mov rax, SYS_exit
    mov rdi, EXIT_FAILURE
    syscall

io_exit:
    mov rax, SYS_exit
    mov rdi, EXIT_SUCCESS
    syscall

io_getchar:
    ; todo: buffering
    mov rax, SYS_read
    mov rdi, STDIN_FILENO
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    cmp rax, 1
    movzx rax, byte[char_buffer]
    mov rcx, 255 ; EOF (?)
    cmovne rax, rcx 
    ret        

io_putchar:
    mov [char_buffer], dil
    ; todo: buffering (?)
    mov rax, SYS_write
    mov rdi, STDOUT_FILENO
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    ret

; inout rsi
%macro IO_PAGEALIGN 1
    lea %1, [%1+PAGESIZE-1]
    and %1, ~(PAGESIZE-1)
%endmacro

; return rax:rdx ptr:size
io_map_file:
    mov rax, SYS_stat
    ; rdi is path
    mov rsi, stat_buffer
    syscall
    cmp rax, 0
    jne .err

    mov rax, SYS_open
    ; rdi is path
    mov rsi, O_RDONLY ; flags
    mov rdx, 0 ; mode
    syscall
    cmp rax, 0
    jl .err

    push rdi
    mov rdi, 0 ; addr
    mov rsi, [stat_buffer+STAT_OFFSET_st_size] ; length
    IO_PAGEALIGN rsi
    mov rdx, PROT_READ ; prot
    mov r10, MAP_PRIVATE ; flags
    mov r8, rax ; fd
    mov r9, 0 ; offset
    mov rax, SYS_mmap
    syscall
    pop rdi

    cmp rax, 0
    jl .err

    mov rdx, [stat_buffer+STAT_OFFSET_st_size]
    ret
.err:
    call io_eprint
    mov rdi, .err_msg
    jmp io_error
.err_msg: db ": failed to open and map file",10,0
