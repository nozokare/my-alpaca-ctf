with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])

import time
import math
import random


class MontgomeryCurve:
    # E: y^2 = x^3 + A*x^2 + x (mod N)
    def __init__(self, A, N):
        self.A = A
        self.N = N
        self.A24 = (A + 2) * pow(4, -1, N) % N

    # P, Q, P-Q から P+Q を計算
    def add(self, P, Q, P_Q):
        a = (P[0] + P[1]) * (Q[0] - Q[1]) % self.N
        b = (P[0] - P[1]) * (Q[0] + Q[1]) % self.N
        c = (a + b) % self.N
        d = (a - b) % self.N
        X = (P_Q[1] * c * c) % self.N
        Z = (P_Q[0] * d * d) % self.N
        return (X, Z)

    # P から P+P を計算
    def double(self, P):
        X, Z = P
        a = (X + Z) * (X + Z) % self.N
        b = (X - Z) * (X - Z) % self.N
        e = (a - b) % self.N
        X2 = (a * b) % self.N
        Z2 = (e * ((self.A24 * e) + b)) % self.N
        return (X2, Z2)

    # [k]P を Montgomery Ladder で計算
    def scalar_multiple(self, k, P):
        R0 = P  # R0 = [1]P
        R1 = self.double(P)  # R1 = [2]P

        # R0 = [m]P, R1 = [m+1]P の形を保ちながら k のビットをみて更新していく
        for i in reversed(range(k.bit_length() - 1)):
            if (k >> i) & 1 == 0:
                R1 = self.add(R1, R0, P)  # R1 = [m+1]P + [m]P = [2m+1]P
                R0 = self.double(R0)  # R0 = [2m]P
            else:
                R0 = self.add(R1, R0, P)  # R0 = [m+1]P + [m]P = [2m+1]P
                R1 = self.double(R1)  # R1 = [2(m+1)]P

        return R0


start = time.time()

B = 2**10
curves = 100

for i in range(curves):
    A = random.randint(0, n - 1)
    curve = MontgomeryCurve(A, n)
    X = random.randint(1, n - 1)
    P = (X, 1)

    for k in range(2, B):
        P = curve.scalar_multiple(k, P)

    d = math.gcd(P[1], n)
    if 1 < d < n:
        print(f"found {d} in {time.time() - start:.2f} sec, {i + 1} curves tried")
        exit(0)

print("failed")
