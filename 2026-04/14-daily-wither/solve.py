import os

nc, host, port = os.getenv("CONNECT").split()

from pwn import remote

conn = remote(host, port)


def Or(a, b):
    return bytes([x | y for x, y in zip(a, b)])


def get_cipher():
    conn.sendline()
    conn.recvuntil(": ")
    return bytes.fromhex(conn.recvline().decode().strip())


flag = get_cipher()
for _ in range(10):
    flag = Or(flag, get_cipher())
    print(flag)
