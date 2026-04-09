import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote
import re

conn = remote(host, port)

for _ in range(5):
    conn.recvuntil(b"const ")
    json_format = conn.recvline().decode().split(" = ")[0]
    json_format = re.sub(r"([a-z]+)", r'"\1"', json_format)
    json_format = json_format.replace("_", "")
    new_format = ""
    while True:
        new_format = re.sub(r"(\[|,) ?,", r"\1 null,", json_format)
        if new_format == json_format:
            break
        json_format = new_format
    json_format = re.sub(r", ?(\]|\})", r"\1", json_format)
    conn.sendline(json_format.encode())

print(conn.recvall().decode())
