import os
import dotenv

os.chdir(os.path.dirname(__file__))
config = dotenv.dotenv_values()
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isnumeric()

# from local import iv_ciphertext, decrypt

# def is_valid_padding(data: bytes) -> bool:
#     return decrypt(data[:16], data[16:])

from pwn import remote

conn = remote(host, port)
line = conn.recvline().decode()
iv_ciphertext = bytes.fromhex(line.split("=")[1])

count = len(iv_ciphertext) // 16
blocks = [iv_ciphertext[i * 16 : (i + 1) * 16] for i in range(count)]


def is_valid_padding(data: bytes) -> bool:
    conn.sendlineafter(b"> ", data.hex().encode())
    result = conn.recvline().strip().decode()
    return result == "True"


def decrypt_block_char(Ci_1: bytes, Ci: bytes):
    data = bytearray([0] * 16) + Ci
    for b in range(256):
        data[15] = b
        if is_valid_padding(data):
            # 末尾から 2 バイト目を変えてパディングが崩れるなら
            # 末尾は `\x01` ではないので別の候補を探す
            data[14] = 1 
            if not is_valid_padding(data):
                continue

            return chr(data[15] ^ 0x01 ^ Ci_1[15])


# [iv][A][l][p][a][c][a][{]...[}][pad]
flag = "Alpaca{"
for i in range(8, count - 2):
    flag += decrypt_block_char(blocks[i - 1], blocks[i])
flag += "}"
print(flag)
