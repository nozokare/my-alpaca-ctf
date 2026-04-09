from pwn import ELF

elf = ELF("./handout/misdirection")
flag_addr = elf.symbols["flag"]
print(elf.data[flag_addr : flag_addr + 0x3C])
print(bytes(reversed(elf.data[flag_addr - 0x3C : flag_addr + 1])))
