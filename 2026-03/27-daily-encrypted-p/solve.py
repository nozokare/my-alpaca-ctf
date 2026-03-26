import os
os.chdir(os.path.dirname(__file__))

import math

with open("handout/output.txt") as f:
    lines = f.readlines()
    n = int(lines[0].split(" = ")[1])
    e = int(lines[1].split(" = ")[1])
    c1 = int(lines[2].split(" = ")[1])
    c2 = int(lines[3].split(" = ")[1])

p = math.gcd(n, c2)
q = n // p

phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)
m = pow(c1, d, n)

print(bytes.fromhex(hex(m)[2:]).decode())
