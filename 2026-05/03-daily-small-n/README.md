# Small N

https://alpacahack.com/daily/challenges/small-n

## 問題の概要

シンプルな RSA 暗号でフラグが暗号化されています。ただし、一方の素数は `q = getPrime(32)` と小さいです。

## 解法

32 ビットの素因数は十分に小さく､ $N$ を素因数分解できます。

```python
import sympy

factors = list(sympy.factorint(n).keys())

p = factors[0]
q = factors[1]

phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)
m = pow(c, d, n)

print(bytes.fromhex(hex(m)[2:]).decode())
# => Alpaca{****************}
```

せっかくなのでいろいろなアルゴリズムを試してみます。

Python は int が多倍長整数で実装上便利ですが、実行速度が遅いため実行環境として [PyPy](https://www.pypy.org/) を使用して実行しています。

## 試し割り法

`q` は $2^{31} < q < 2^{32}$ の範囲の素数です。この範囲内の奇数は約 10 億個程度で、十分に試し割り法で全探索可能です。

```python
start = time.time()

for q in range(2**31 + 1, 2**32, 2):
    if n % q == 0:
        print(f"found {q} in {time.time() - start:.2f} sec")
        exit(0)
# => found ***** in 7.79 sec
```

見つかった `q` は探索範囲の 20% 程度の位置にあったので、最悪のケースでも 40 秒程度で見つけられます。

## Pollard の ρ 法

合成数 $n$ に対して、適当な関数 $$f(x) = x^2 + c\ \ \mathrm{mod}\ n$$ などを定め、初期値 $x_0$ から

$$x_{i+1} = f(x_i)$$

のように数列を生成します。この数列を $\mathrm{mod}\ p$ で見ると $p$ 通りの値しか取りえないため、鳩ノ巣原理によってある時点で衝突

$$x_i \equiv x_j \pmod{p}\quad (i \neq j)$$

が起こり、それ以降は同じ数列を繰り返すことになります。このとき $x_i - x_j$ は $p$ の倍数となるため､

$$\gcd(|x_i - x_j|, n)$$

を計算することで $p$ を見つけることができます。

<a title="忍者猫, CC0, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Pollard_rho_cycle.svg"><img width="330" alt="Pollard rho cycle" src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Pollard_rho_cycle.svg/330px-Pollard_rho_cycle.svg.png?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=thumbnail"></a><br>Pollard rho cycle: WikiMedia Commons より, Author: 忍者猫

衝突 $x_i \equiv x_j \pmod{p}$ を検出する方法として、Floyd の循環検出アルゴリズムを使用します。

これは $x_i$ と $x_{2i}$ を比較していく方法で、循環部分に入ったあとは相対速度 1 で両者が近づいていくため､ $x_i \equiv x_j \pmod{p}$ となる点を見つけることができます。

### 実装

今回は $f(x) = x^2 + 1$ を使用して実装してみます。

```python
start = time.time()

x = y = 2
d = 1

while d != n:
    x = (x * x + 1) % n
    y = (y * y + 1) % n
    y = (y * y + 1) % n
    d = math.gcd(abs(x - y), n)
    if 1 < d < n:
        print(f"found {d} in {time.time() - start:.2f} sec")
        exit(0)

print("failed")

# => found ***** in 0.24 sec
```

$d=n$ となるのは $\mathrm{mod}\ p$ と $\mathrm{mod}\ q$ で同時に衝突が起こる場合で、この場合は $f$ や初期値を変える必要があります。

### 既存の実装

[GNU Coreutils の `factor` コマンド](https://www.gnu.org/savannah-checkouts/gnu/coreutils/manual/html_node/factor-invocation.html) は小さい素因数を試し割り法で除いた後に Pollard の ρ 法で素因数分解を行っています。

ただし、循環検出には Brent 法を使用しており、これが今回の $p>>q$ の状況と相性が悪いのか、`factor` コマンドでは素因数分解できませんでした。

## Pollard の $p-1$ 法

たくさんの因数を持つような $M$ をつくり、もしこれが $p-1$ の倍数になっていれば

$$a^M = (a^{p-1})^k \equiv 1 \pmod{p}$$

となるので、このとき $\gcd(a^M - 1, n)$ で $p$ を回収できます。

$p-1$ 法は $p-1$ が小さい素因数しか持たないような $p$ が $n$ の素因数に含まれている場合に成功します。

### 実装

今回は雑に $M = B!$ として実装してみます。

```python
start = time.time()

a = 2
B = 2**16

for p in range(2, B):
    a = pow(a, p, n)

d = math.gcd(a - 1, n)

if 1 < d < n:
    print(f"found {d} in {time.time() - start:.2f} sec")
else:
    print("failed")

# => found ***** in 0.47 sec
```

$d = 1$ となるのは $M$ が $p-1$ の倍数になっていない場合で､ $B$ を大きくする必要があります。

$d = n$ となるのは $M$ が $q-1$ の倍数にもなってしまった場合です。

### 既存の実装

[GMP-ECM](https://gitlab.inria.fr/zimmerma/ecm/) は ECM に加えて $p-1$ 法､ $p+1$ 法も実装されています。

`-pm1` を指定することで $p-1$ 法を使用して素因数分解できます。

```bash
$ sudo apt install gmp-ecm
$ head -n1 output.txt | cut -d= -f2 | ecm -pm1 10000
Input number is 2857.....9213 (164 digits)
Using B1=10000, B2=632208, polynomial x^1, x0=662909043
Step 1 took 0ms
Step 2 took 0ms
********** Factor found in step 2: 256....311
Found prime factor of 10 digits: 256....311
Prime cofactor 111.....483 has 155 digits
```

Step 1 では $M = \mathrm{lcm}(1, 2, \ldots, B_1)$ で $\gcd(a^M - 1, n)$ を計算し、Step 2 では追加で $p-1$ に $B_1 < q \leq B_2$ の素因数が含まれる場合を $M\cdot q$ で拾うようになっています。

## ECM (Elliptic Curve Method)

たくさんの因数を持つような $M$ をつくり、楕円曲線 $E$ と点 $P$ をランダムに選んで $E$ の $\mathbb{F}_p$-有理点がなす群 $E(\mathbb{F}_p)$ を考えます。もし $M$ が $\\#E(\mathbb{F}_p)$ の倍数になっていれば

$$[M]P = \mathcal{O}$$

となるため､ $E(\mathbb{Z}/n\mathbb{Z})$ 上で $[M]P$ を計算する過程で $\mathbb{Z}/n\mathbb{Z}$ 上で逆元が存在しないような数が現れ､ $n$ の非自明な約数を見つけることができます。

$p-1$ 法では $N$ を決めた時点で群の位数が固定されており､ $M$ が $p-1$ の倍数になるまで $B$ を大きくしていく必要がありましたが、ECM では楕円曲線が変わると群の位数が変化するため､ $M$ が $\\#E(\mathbb{F}_p)$ の倍数になるような曲線に当たるまでランダムに曲線を取り替えて試行することができます。

### 実装

今回は楕円曲線は Montgomery 曲線 $$E: y^2 = x^3 + A x^2 + x \pmod{n}$$ をとり､ $y$ 座標を使わずに計算する方法を実装してみます。

Montgomery 曲線では $y$ 座標を使わずに

- $P$, $Q$, $P-Q$ から $P+Q$ を計算する
- $P$ から $P+P$ を計算する

ことができます。

$[k]P$ の計算は Montgomery Ladder と呼ばれる方法で､ $R_1 - R_0 = P$ という関係を保ちながら $R_0 = [m]P$､ $R_1 = [m+1]P$ を更新していくことで効率的に計算できます。

```python
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

# => found ****** in 0.60 sec, 18 curves tried
```

### 既存の実装

[GMP-ECM](https://gitlab.inria.fr/zimmerma/ecm/) はデフォルトで ECM を使用して素因数分解を行います。

```bash
$ head -n1 output.txt | cut -d= -f2 | ecm 10000
GMP-ECM 7.0.6 [configured with GMP 6.3.0, --enable-asm-redc] [ECM]
Input number is 2857.....9213 (164 digits)
Using B1=10000, B2=1873422, polynomial x^1, sigma=1:1729060067
Step 1 took 7ms
********** Factor found in step 1: 256....311
Found prime factor of 10 digits: 256....311
Prime cofactor 111.....483 has 155 digits
```
