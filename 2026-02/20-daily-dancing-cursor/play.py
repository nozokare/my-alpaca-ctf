import os

os.chdir(os.path.dirname(__file__))

with open("flag.txt") as f:
    data = f.read().strip()

import time

for c in data:
    print(c, end="", flush=True)
    time.sleep(0.02)
    if c == "K":
        pass
