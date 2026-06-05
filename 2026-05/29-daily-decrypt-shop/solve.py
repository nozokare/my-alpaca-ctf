import os

nc, host, port = os.environ.get("CONNECT", "nc localhost 1337").split()

from pwn import remote
from Crypto.Util.number import long_to_bytes

conn = remote(host, int(port))

conn.recvuntil(b"n = ")
n = int(conn.recvline().strip())
conn.recvuntil(b"c = ")
c = int(conn.recvline().strip())

conn.sendlineafter(b"> ", str(n - c).encode())
m = int(conn.recvline().strip())
print(long_to_bytes(n - m))
