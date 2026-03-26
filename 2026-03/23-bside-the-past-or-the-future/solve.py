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

# 2 周目の終わりまでの出力を取得
request_count = N * 2 - 128
con.send(("1\n" * request_count).encode())

values = []
for _ in range(request_count):
    con.recvuntil(b"[present] ")
    values.append(int(con.recvline().strip()))

# 出力から状態を復元
states = [untemper(val) for val in values]
state_current = np.array(states[-N:], dtype=np.uint32)  # 2周目の state[]
state_past = untwist(state_current)  # 1周目の state[] を復元
state_future = twist(state_current)  # 3周目の state[] を予測

# 復元した状態が正しいか確認
for i in range(N - 128):
    assert state_past[i + 128] == states[i]

# 未来の出力を予測して送信
con.sendline(b"2")
con.recvuntil(b"i = ")
i = int(con.recvline().strip())
con.send(f"{temper(state_future[i])}\n".encode())

# 過去の出力を予測して送信
con.recvuntil(b"i = ")
i = int(con.recvline().strip(b"?\n"))
con.send(f"{temper(state_past[i])}\n".encode())

con.interactive()
