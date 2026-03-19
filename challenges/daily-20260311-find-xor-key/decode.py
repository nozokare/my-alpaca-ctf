from pathlib import Path
from itertools import cycle

filename = Path(__file__).parent / ".src" / "find-xor-key" / "output.txt"
with open(filename, "r") as f:
    data = bytes.fromhex(f.readline().strip())

flag_orig = b"Alpaca{"

key = bytes([data[i] ^ flag_orig[i] for i in range(7)])
flag = bytes([c ^ k for c, k in zip(data, cycle(key))])

print(flag.decode())
