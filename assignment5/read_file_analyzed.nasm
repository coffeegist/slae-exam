00000000      jmp short 0x38        ; JMP (jmp-call-pop)

00000002      mov eax,0x5           ; SYSCALL(5) // man 2 open
00000007      pop ebx               ; POP (jmp-call-pop) "/etc/motd" stored in ebx from jump-call-pop method
00000008      xor ecx,ecx           ; Clear ECX
0000000A      int 0x80              ; Call OPEN("/etc/motd")

0000000C      mov ebx,eax           ; call to open returns FD, store FD in EBX
0000000E      mov eax,0x3           ; SYSCALL(3) // man 2 read
00000013      mov edi,esp           ; Store stack pointer in EDI
00000015      mov ecx,edi           ; Store stack pointer in ECX (*buf for read destination)
00000017      mov edx,0x1000        ; Number of bytes to read
0000001C      int 0x80              ; Call READ(3, esp, 0x1000)

0000001E      mov edx,eax           ; Returns number of bytes read
00000020      mov eax,0x4           ; SYSCALL(4) // man 2 write
00000025      mov ebx,0x1           ; FD to write to (stdout)
0000002A      int 0x80              ; Call WRITE(stdout, esp, numberOfBytesRead)

0000002C      mov eax,0x1           ; SYSCALL(1) // man 2 exit
00000031      mov ebx,0x0           ; return code of 0
00000036      int 0x80              ; Call exit(0)

00000038      call dword 0x2        ; CALL (jmp-call-pop)

0000003D      das                   ; /
0000003E      gs jz 0xa4            ; etc
00000041      das                   ; /
00000042      insd                  ; m
00000043      outsd                 ; o
00000044      jz 0xaa               ; td
00000046      db 0x00               ; 0x0
