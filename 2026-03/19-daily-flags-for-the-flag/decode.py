
from pathlib import Path

filepath = Path(__file__).parent / ".src" / "flags-for-the-flag" / "output.txt"

with open(filepath, "r") as f:
    data = f.readline().strip()

def unrisl(s: bytes) -> str:
    i = 0
    res = []
    while i < len(s):
        if s.startswith(b"\xf0\x9f\x87", i):
            res.append(chr(s[i+3] - 0xA6 + ord("A")))
            i += 4
        else:
            res.append(s[i:i+1].decode())
            i += 1
    return "".join(res)

print(unrisl(data.encode("utf-8")))
