with open("handout/chall.txt") as f:
    data = dict(line.strip().split(" = ") for line in f)

n = int(data["n"])
e1 = int(data["e1"])
e2 = int(data["e2"])
c1 = int(data["c1"])
c2 = int(data["c2"])

import math


def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y


gcd, k1, k2 = extended_gcd(e1, e2)
print(f"gcd = {gcd}, k1 = {k1}, k2 = {k2}")

mm = (pow(c1, k1, n) * pow(c2, k2, n)) % n
m = math.isqrt(mm)
assert m * m == mm

print(bytes.fromhex(hex(m)[2:]))
