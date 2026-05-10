# reused n

https://alpacahack.com/daily/challenges/reused-n

## 問題の概要

RSA 暗号でフラグが $(e_1, n)$ と $(e_2, n)$ で暗号化されています。

```python
assert len(flag) < 100

m = bytes_to_long(flag)

p = getPrime(1024)
q = getPrime(1024)
n = p * q

e1 = 1234
e2 = 5678

c1 = pow(m, e1, n)
c2 = pow(m, e2, n)
```

与えられているのは $n$, $e_1$, $e_2$, $c_1$, $c_2$ です。

## 解法

$\gcd(e_1, e_2)$ を計算すると 2 でした。拡張ユークリッドの互除法を使うと

$$\gcd(e_1, e_2) = k_1 e_1 + k_2 e_2$$

となる $k_1, k_2$ が求まります。これを用いると

$$c_1^{k_1} \cdot c_2^{k_2} \equiv m^{k_1 e_1 + k_2 e_2} \equiv m^2 \pmod{n}$$

が得られます。$n$ が 2048 ビット程度に対して $m$ は 100 × 8 ビット未満と小さく､ $m^2 < n$ で $\mathrm{mod}\ n$ の剰余が発生しないため、そのまま整数の平方根を取るだけで $m$ を求めることができます。

## 解答に使用したコード

```python
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
```
