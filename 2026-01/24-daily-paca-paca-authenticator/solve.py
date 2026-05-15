import os

nc, host, port = os.getenv("CONNECT", "nc localhost 1337").split(" ")

from pwn import remote, xor

conn = remote(host, int(port))

iv = bytes.fromhex(conn.recvline().strip().decode().split(" ")[-1])
flip = xor(b'{"name": "alpaca', b'{"name":  "llama')
new_iv = xor(iv, flip)

conn.sendlineafter(b"> ", new_iv.hex().encode())
print(conn.recvall().decode())
