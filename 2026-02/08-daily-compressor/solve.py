import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote

conn = remote(host, port)

flag_charset = "abcdefghijklmnopqrstuvwxyz_"


def guess_next_char(prefix: str) -> str:
    conn.sendlines([(prefix + c) * 5 for c in flag_charset])
    min_size = 2**32
    min_char = None
    for c in flag_charset:
        match = conn.recvregex(rb".*Size of compressed data: (\d+) bytes", capture=1)
        size = int(match.group(1))
        if size < min_size:
            min_size = size
            min_char = c
    return min_char


flag = "Alpaca{"

while len(flag) < 52:
    flag += guess_next_char(flag)
    print(f"flag = {flag}")

flag += "}"
print(f"flag = {flag}")
