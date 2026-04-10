import ast

with open("handout/output.txt", "r") as f:
    reminders = ast.literal_eval(f.readline())

# fmt: off
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349]
# fmt: on

import math

# from sympy.ntheory.modular import crt
# flag, modulo = crt(primes, reminders)
# print(flag.to_bytes(math.ceil(flag.bit_length() / 8), "big").decode())


def extended_gcd(a: int, b: int) -> tuple[int, int, int]:
    """gcd(a, b) と ax + by = gcd(a, b) を満たす整数 x, y を返す"""
    # a=0 なら gcd(0, b) = a * 0 + b * 1
    if a == 0:
        return b, 0, 1

    gcd, u, v = extended_gcd(b % a, a)
    # (b - b//a * a) * u + a * v = gcd(b % a, a) = gcd(a, b) が成り立つので
    # a * (v - (b // a) * u) + b * u = gcd(a, b)
    return gcd, v - (b // a) * u, u


def chinese_remainder_theorem(a: int, b: int, m: int, n: int) -> int:
    """
    連立合同式 x ≡ a (mod m) & x ≡ b (mod n) の解 x を求める
    (中国の剰余定理から m, n が互いに素ならば mod mn で解が一意に定まる)
    """
    # mu + nv = 1 を満たす整数 u, v を求める
    gcd, u, v = extended_gcd(m, n)
    assert gcd == 1, "m, n should be coprime"
    # x = anv + bmu とすると
    # x = a(1-mu) + bmu ≡ a (mod m) かつ
    # x = anv + b(1-nv) ≡ b (mod n) を満たすので、これが解となる
    return (a * n * v + b * m * u) % (m * n)


M = primes[0]
x_k = reminders[0]
for k in range(1, len(primes)):
    x_k = chinese_remainder_theorem(x_k, reminders[k], M, primes[k])
    M *= primes[k]

print(x_k.to_bytes(math.ceil(x_k.bit_length() / 8), "big").decode())
