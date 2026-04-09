import os

nc, host, port = os.getenv("CONNECT").split(" ")
assert nc == "nc" and host and port.isdecimal()

from pwn import remote

conn = remote(host, port)
ciphertext = conn.recvline().split(b" ")[1]

flag_charset = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{}_"

patterns = []
for c1 in flag_charset:
    for c2 in flag_charset:
        patterns.append(bytes([c1] * 8 + [c2] * 8).hex())

conn.sendline("".join(patterns))

conn.recvuntil(b"ciphertext(hex): ")
table = {}
for c1 in flag_charset:
    for c2 in flag_charset:
        cipher_block = conn.recvn(32)
        table[cipher_block] = chr(c1) + chr(c2)

flag = ""
for i in range(0, len(ciphertext), 32):
    cipher_block = ciphertext[i : i + 32]
    if cipher_block in table:
        flag += table[cipher_block]
    else:
        flag += "??"

print(flag)
