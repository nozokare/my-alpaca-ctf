from dotenv import dotenv_values
from pathlib import Path

config = dotenv_values(Path(__file__).parent / ".env")
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isdigit(), "Invalid CONNECT string"

from pwn import *
from mt19937 import twist, untwist, temper, untemper, N, warmup
import numpy as np

warmup()

con = remote(host, int(port))

request_count = N * 2 - 128
con.send("1\n" * request_count)

values = []
for _ in range(request_count):
    con.recvuntil(b"[present] ")
    values.append(int(con.recvline().strip()))

states = [untemper(val) for val in values]
state_current = np.array(states[-N:], dtype=np.uint32)
state_past = untwist(state_current)
state_future = state_current.copy()
twist(state_future)

for i in range(128, N):
    assert state_past[i] == states[i - 128]

con.sendline("2")
con.recvuntil(b"i = ")
i = int(con.recvline().strip())
con.send(f"{temper(state_future[i])}\n")

con.recvuntil(b"i = ")
i = int(con.recvline().strip(b"?\n"))
con.send(f"{temper(state_past[i])}\n")

con.interactive()
