format ELF64 executable

SYS_WRITE=1
SYS_EXIT=60

macro write fd,buf,count
{
        mov rax,SYS_WRITE
        mov rdi,fd
        mov rsi, buf
        mov rdx,count
        syscall
}

// fasm is somewhat a preprocessor we can have compile time variables
// we can use compile time loops  etc ... 
// however fasm eventually will interpret them then generate the raw assembly/binary code
// you can think of everything like macros
// inter. language that outputs machine instructions
 



macro exit code
{
        mov rax,SYS_EXIT
        mov rdi,code
        syscall
}

segment readable executable
entry main

main:

        write 1,msg,msg_len

        exit 0



segment readable writeable
msg db "Hello, Wordl!",10
msg_len = $-msg

