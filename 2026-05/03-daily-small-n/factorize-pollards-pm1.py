with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])

import time
import math

start = time.time()

a = 2
B = 2**16

for p in range(2, B):
    a = pow(a, p, n)

d = math.gcd(a - 1, n)

if 1 < d < n:
    print(f"found {d} in {time.time() - start:.2f} sec")
else:
    print("failed")
