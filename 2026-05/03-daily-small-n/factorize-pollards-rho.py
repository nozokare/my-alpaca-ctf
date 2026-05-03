with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])

import time
import math

start = time.time()

x = y = 2
d = 1

while d != n:
    x = (x * x + 1) % n
    y = (y * y + 1) % n
    y = (y * y + 1) % n
    d = math.gcd(abs(x - y), n)
    if 1 < d < n:
        print(f"found {d} in {time.time() - start:.2f} sec")
        exit(0)

print("failed")
