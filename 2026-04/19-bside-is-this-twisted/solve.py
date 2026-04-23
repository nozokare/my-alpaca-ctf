import os

nc, host, port = os.environ["CONNECT"].split(" ")

from pwn import remote
from mt19937 import twist, untwist, untemper, warmup

warmup()

conn = remote(host, int(port))

import ast

for r in range(128):
    conn.recvuntil(b"/128\n")
    a = ast.literal_eval(conn.recvline().decode())

    state = [untemper(y) for y in a]
    state_untwisted = untwist(state)
    state_retwisted = twist(state_untwisted)

    if state_retwisted[0] == state[0]:
        print(f"{r + 1}/128: mt19937")
        conn.sendline(b"1")
    else:
        print(f"{r + 1}/128: not mt19937")
        conn.sendline(b"0")

print(conn.recvall().decode())
