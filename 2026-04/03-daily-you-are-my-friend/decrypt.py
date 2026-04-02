import os

os.chdir(os.path.dirname(__file__))

import ast

with open("handout/output.txt") as f:
    cts = ast.literal_eval(f.readline())


def rot13_char(c: str):
    if "a" <= c <= "z":
        return chr((ord(c) - ord("a") + 13) % 26 + ord("a"))
    if "A" <= c <= "Z":
        return chr((ord(c) - ord("A") + 13) % 26 + ord("A"))
    return c


ct = [0] * len(cts)
ct[0] = ord(rot13_char("A"))
for i in range(1, len(cts)):
    ct[i] = cts[i] ^ ct[i - 1]

flag = [rot13_char(chr(c)) for c in ct]
print("".join(flag))
