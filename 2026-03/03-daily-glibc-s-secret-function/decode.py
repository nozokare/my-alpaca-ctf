from pwn import *

elf = ELF("handout/chal")

addr = elf.symbols["expected"]
expected = elf.data[addr : addr + 112]

decoded = [b ^ 42 for b in expected]
print(bytes(decoded))
