import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote

conn = remote(host, int(port))

HANDS = [b"r", b"p", b"s"]
ROUNDS = 1000

hand = b"r"
for i in range(ROUNDS):
    conn.sendlineafter(b"> ", hand)
    conn.recvuntil(b"Opponent: ")
    opponent = conn.recv(1)
    hand = HANDS[(HANDS.index(opponent) + 1) % 3]
    conn.recvuntil(b"Win count: ")
    win_count = conn.recvline().decode().strip()
    print(f"Round: {i + 1}, Win count: {win_count}")

print(conn.recvall().decode())
