import os
import dotenv

os.chdir(os.path.dirname(__file__))
config = dotenv.dotenv_values()
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isnumeric()

# from local import iv_ciphertext, decrypt

# def oracle(data: bytes) -> bool:
#     return decrypt(data[:16], data[16:])

from pwn import remote

conn = remote(host, port)
line = conn.recvline().decode()
iv_ciphertext = bytes.fromhex(line.split("=")[1])

bs = 16
bc = len(iv_ciphertext) // bs
blocks = [iv_ciphertext[i * bs : (i + 1) * bs] for i in range(bc)]


def oracle(data: bytes) -> bool:
    conn.sendlineafter(b"> ", data.hex().encode())
    result = conn.recvline().strip().decode()
    return result == "True"


def decrypt_block_char(Ci_1: bytes, Ci: bytes):
    data = bytearray([0] * 16) + Ci
    for b in range(256):
        data[15] = b
        if oracle(data):
            c = chr(data[15] ^ 0x01 ^ Ci_1[15])
            if c.isprintable():
                return c


# [iv][A][l][p][a][c][a][{]...[}][pad]
flag = "Alpaca{"
for i in range(8, bc - 2):
    flag += decrypt_block_char(blocks[i - 1], blocks[i])
flag += "}"
print(flag)
