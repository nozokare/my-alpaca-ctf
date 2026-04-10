# RRe_Time_Limiter

https://alpacahack.com/daily/challenges/rre-time-limiter

## 問題の概要

中国の剰余定理でフラグを復元する問題です。
フラグのビット列を整数として、2 ～ 349 の素数で割った余りが与えられています。

## 解法

`sympy` の `crt` に投げるだけで解けますが、せっかくなので [Wikipedia](https://ja.wikipedia.org/wiki/%E4%B8%AD%E5%9B%BD%E3%81%AE%E5%89%B0%E4%BD%99%E5%AE%9A%E7%90%86) を参考に、証明通りに中国の剰余定理を実装してみます。

合同式が 2 本の場合は、以下のようにして解を求めることができます。

```python
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
```

拡張ユークリッドの互除法は帰納的に次のように実装できます。

```python
def extended_gcd(a: int, b: int) -> tuple[int, int, int]:
    """gcd(a, b) と ax + by = gcd(a, b) を満たす整数 x, y を返す"""
    # a=0 なら gcd(0, b) = a * 0 + b * 1
    if a == 0:
        return b, 0, 1

    gcd, u, v = extended_gcd(b % a, a)
    # (b - b//a * a) * u + a * v = gcd(b % a, a) = gcd(a, b) が成り立つので
    # a * (v - (b // a) * u) + b * u = gcd(a, b)
    return gcd, v - (b // a) * u, u
```

合同式が $x \equiv a_k \pmod{m_k}\ (k = 1, \dots, N)$ の $N$ 本の場合は、[帰納法での証明](https://ja.wikipedia.org/wiki/%E4%B8%AD%E5%9B%BD%E3%81%AE%E5%89%B0%E4%BD%99%E5%AE%9A%E7%90%86#%E4%B8%80%E8%88%AC%E7%9A%84%E3%81%AA%E5%AE%9A%E7%90%86%E3%81%AE%E8%A8%BC%E6%98%8E) に従って解を求めます。

$k$ 番目までの合同式を満たす解 $x_k$ が求まっているとき、次の合同式

$$
\begin{aligned}
x_{k+1} &\equiv x_k \pmod{m_1\cdots m_{k}} \\
x_{k+1} &\equiv a_{k+1} \pmod{m_{k+1}}
\end{aligned}
$$

を満たす $x_{k+1}$ を求めれば $k+1$ 番目までの合同式を満たす解が求まります。これを繰り返せば $N$ 番目までの合同式を満たす解が求まります。

```python
M = primes[0]
x_k = reminders[0]
for k in range(1, len(primes)):
    x_k = chinese_remainder_theorem(x_k, reminders[k], M, primes[k])
    M *= primes[k]
```
