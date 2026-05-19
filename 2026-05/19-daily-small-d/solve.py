# Wiener's Attack

with open("handout/output.txt") as f:
    data = dict(line.strip().split(" = ") for line in f)

n = int(data["n"])
e = int(data["e"])
c = int(data["c"])

from Crypto.Util.number import long_to_bytes


# n/d を連分数展開
def continued_fraction(n, d):
    while d != 0:
        yield n // d
        n, d = d, n % d


# 連分数展開の途中までを分数 p/q の形にしたものを列挙
def convergents(cf):
    p0, p1 = 0, 1
    q0, q1 = 1, 0

    for a in cf:
        p0, p1 = p1, a * p1 + p0
        q0, q1 = q1, a * q1 + q0
        yield p1, q1


# ed = kφ(n) + 1 ⇒ e/n ≈ k/d なので、e/n の連分数展開の
# i 番目までを分数にした有理数近似 k_i/d_i を列挙すると k/d が見つかる
for k, d in convergents(continued_fraction(e, n)):
    if k == 0:
        continue
    # φ(n) = (ed - 1) / k が整数にならない場合はスキップ
    if (e * d - 1) % k != 0:
        continue

    print(f"d = {d}:")
    m = pow(c, d, n)
    flag = long_to_bytes(m)
    if flag.startswith(b"Alpaca"):
        print(flag)
