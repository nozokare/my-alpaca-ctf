import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote

conn = remote(host, port)

while (line := conn.recvline()).endswith(b"(y/n)\n"):
    cards = conn.recvline().decode()[-6:-1]
    conn.sendline(b"y" if "♡♡♡" in (cards + cards) else b"n")

print(line.decode())
