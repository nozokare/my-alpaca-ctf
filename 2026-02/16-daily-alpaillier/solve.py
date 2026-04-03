import os

os.chdir(os.path.dirname(__file__))

import ast

with open("handout/output.txt") as f:
    for line in f.readlines():
        if line.startswith("n = "):
            n: int = ast.literal_eval(line.split(" = ")[1])
        elif line.startswith("c = "):
            cs: list[int] = ast.literal_eval(line.split(" = ")[1])

n2 = n * n
dic = {}
cA = cs[0]
for i in range(0x20, 0x7F):
    dic[(cA * pow(1 + n, i - ord("A"), n2)) % n2] = chr(i)

print("".join(dic[c] if c in dic else "?" for c in cs))
