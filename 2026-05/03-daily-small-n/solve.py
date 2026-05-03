with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])
e = int(data["e"])
c = int(data["c"])

import sympy

factors = list(sympy.factorint(n).keys())

p = factors[0]
q = factors[1]

phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)
m = pow(c, d, n)

print(bytes.fromhex(hex(m)[2:]).decode())
