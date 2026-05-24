# Even Worse RSA

https://alpacahack.com/daily/challenges/even-worse-rsa

## 問題の概要

ランダムな素数 $p$ を選び、整数化したフラグ $m$ を

$$c = m^e\ \mathrm{mod}\ p$$

で暗号化(?) しています。普段は $e=65537$ が使われることが多いですが、今回は $e=65538$ になっています。

与えられているのは $p$, $e$, $c$ です。

## 解法

普通の RSA では $(m^e)^d \equiv m \pmod{N}$ となるような秘密鍵 $d$ が存在して、それを知るには $N$ を素因数分解する必要がある、という感じで公開鍵暗号として成立しています。

今回は群の位数が $p-1$ と判明してしまっているので、拡張ユークリッドの互除法で

$$ed + k(p-1) = \gcd(e, p-1)\ (=:g)$$

となる $d$ を求めれば

$$(m^e)^d = m^{g-k(p-1)} = m^g\cdot (m^{p-1})^{-k} \equiv m^g \pmod{p}$$

が得られ､ $g = 1$ であれば $m$ を復号できます。

今回は $e$ が偶数なので $p-1$ と互いに素ではなく、実際に計算してみると $\gcd(e, p-1) = 6$ でした。

$m^6$ の 6 乗根を求めれば $m$ を復元できそうなので、SageMath で計算してみます。

```sage
g, d, k = xgcd(e, p - 1)  # e*d + (p-1)*k = g
mg = pow(c, d, p)  # (m^e)^d ≡ m^g (mod p)

R.<x> = PolynomialRing(Zmod(p))
f = x^6 - mg
for m in f.roots():
    print(bytes.fromhex(hex(m[0])[2:]))
# =>
# b"\xa7\x1a\x805\xbd\x85'\xab\xc9..."
# b'\x88\x11\xf7\xb4:\xe1\x12\xcb~@...'
# b'\x88\x11\xf7\xb4:\xe1\x12\xcb~@...'
# b'\x1f\x08\x88\x81\x82\xa4\x14\xe0...'
# b'\x1f\x08\x88\x81\x82\xa4\x14\xe0...'
# b'Alpaca{*********}'
```

6 つの根のうち 1 つがフラグになり、復元することができました。

## 感想

`even worse`(さらに悪い) と `even`(偶数) がかかっていてうまいタイトルだと思いました。

`roots` の具体的な計算方法を SageMath に任せきりなので、具体的なアルゴリズムを調べるのは宿題にしたいと思います。
