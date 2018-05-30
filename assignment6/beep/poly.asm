global _start

section .text
_start:
   ;     int fd = open("/dev/tty10", O_RDONLY);
   xor eax, eax
   mov al, 5
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
   mov al, 54
   mov cx, 0x4b30
   mov edx, 66729180
   int 80h
