import os

nc, host, port = os.getenv("CONNECT", "nc localhost 1337").split(" ")

from pwn import remote
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

conn = remote(host, port)

conn.recvuntil(b"key: ")
key = bytes.fromhex(conn.recvline().decode().strip())
ALPACA = chr(129433)
plaintext = (ALPACA * 5).encode()
cipher = AES.new(key, AES.MODE_CBC)
ciphertext = cipher.encrypt(pad(plaintext, AES.block_size))

conn.sendlineafter(b": ", ciphertext.hex().encode())
conn.sendlineafter(b": ", cipher.iv.hex().encode())
print(conn.recvall().decode())
