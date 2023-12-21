format ELF64 executable

SYS_WRITE equ 1
SYS_EXIT equ 60
SYS_SOCKET equ 41
SYS_BIND equ 49
SYS_LISTEN equ 50
SYS_CLOSE equ 3
SYS_ACCEPT equ 43

STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0
MAX_CONN equ 5


macro write fd,buf,count
{
	mov rax,SYS_WRITE
	mov rdi,fd
	mov rsi,buf
	mov rdx,count
	syscall
}

macro exit code 
{
	mov rax,SYS_EXIT
	mov rdi,code
	syscall
}


macro socket domain,type,protocol
{
	mov rax,SYS_SOCKET
	mov rdi,domain	
	mov rsi,type
	mov rdx,protocol
	syscall

}

macro syscall2 number, a,b
{
	mov rax,number
	mov rdi,a
	mov rsi,b
	syscall
}

macro listen sockfd , backlog
{
	syscall2 SYS_LISTEN,  sockfd,backlog
}

macro syscall3 number,a,b,c{
	mov rax, number
	mov rdi,a
	mov rsi,b
	mov rdx,c
	syscall
}

macro bind sockfd , servaddr , sizeof_servaddr 
{
	syscall3 SYS_BIND , sockfd,servaddr,sizeof_servaddr
}


macro syscall1 number, a {
	mov rax,number
	mov rdi , a	
	syscall
}

macro close sockfd 
{
	 syscall1 SYS_CLOSE,sockfd

}


macro accept sockfd , cliaddr, cliaddr_len
{
	syscall3 SYS_ACCEPT , sockfd , cliaddr , cliaddr_len
}




segment readable executable
entry main
main:
	write STDOUT,start,start_len
	
	write STDOUT , socket_trace_msg,socket_trace_msg_len
	socket AF_INET,SOCK_STREAM,0	
        cmp rax,0
        jl error	
	mov qword [sockfd],rax
	mov word [servaddr.sin_family],AF_INET
	mov dword [servaddr.sin_addr],INADDR_ANY
	mov word [servaddr.sin_port], 14619
	

	write STDOUT, bind_trace_msg , bind_trace_msg_len
	bind [sockfd] , servaddr.sin_family, sizeof_servaddr
	cmp rax , 0
	jl error	
	
	write STDOUT , listen_trace_msg , listen_trace_msg_len
	listen [sockfd] , MAX_CONN
	cmp rax, 0
	jl error

next_request:		
	write STDOUT,accept_trace_msg,accept_trace_msg_len
	accept [sockfd] ,cliaddr.sin_family,sizeof_cliaddr	
	cmp rax,0
	jl error
	
	mov qword [connfd] ,rax
	
	write [connfd],response,response_len	
	
	jmp next_request

	write STDOUT,ok_msg,ok_msg_len	
	close [sockfd]
	close [connfd]
	exit EXIT_SUCCESS


error : 
	write STDERR,error_msg,error_msg_len
	close [sockfd]
	close [connfd]
	exit EXIT_FAILURE

segment readable writeable


struc servaddr_in
{
	.sin_family dw 0
	.sin_port dw 0
	.sin_addr dd 0
	.sin_zero dq 0
	;;.size dd $ - .sin_family
}


;; 0 is reserved for stdin and we dont want to close it accid
sockfd dq -1
connfd dq -1
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family

cliaddr servaddr_in
sizeof_cliaddr dd sizeof_servaddr

response	db "HTTP/1.1 200 OK",13,10
		db "Content-Type: text/html; charset=utf-8",13,10
		db "Connection:close",13,10
		db 13,10
		db "<h1>Hello MEGAlol </h1>",10
response_len = $-response






;;Messages
hello db "HELOLO",10
hello_len = $-hello
error_msg db "ERROR: An Error Occured",10,10
error_msg_len = $-error_msg
start db 10,10,"--------Web Server Starting-----",10
start_len = $-start
socket_trace_msg db "INFO: Creating a Socket...",10
socket_trace_msg_len = $ - socket_trace_msg
ok_msg db "INFO: OK!",10,10
ok_msg_len = $-ok_msg 
bind_trace_msg db "INFO: Binding The Socket ...",10
bind_trace_msg_len = $ - bind_trace_msg
listen_trace_msg db "INFO: Listenning on the Socket ...",10
listen_trace_msg_len = $ - listen_trace_msg
accept_trace_msg db 10,10,10,"INFO: Waiting for a Connection ...",10
accept_trace_msg_len = $ - accept_trace_msg



;;struct sockaddr_in {
;; sa_family_t 	sin_family ; 	//16bits
;; in_port_t 	sin_port ; 	//16bits
;; struct in_addr sin_addr ; 	//32bits
;; uint8_t 	sin_zero[8]; 	//64 bits
;;}
