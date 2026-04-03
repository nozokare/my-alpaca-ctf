# Alpaillier

https://alpacahack.com/daily/challenges/alpaillier

## 問題の概要

RSA 暗号風の暗号方式で暗号化されたフラグを復号する問題です。

Python で以下のように暗号化が行われています。

- $p, q$： 512 ビットの素数
- $n = p \cdot q$
- $r$： $2 \leq r < n-1$ のランダムな整数 (n と互いに素)

とし、フラグの各文字 `b` を以下の式で暗号化します。

- $c = (1+n)^b \cdot r^n\ \mathrm{mod}\ n^2$

$n$ と $c$ の配列が与えられています。

## 解法を考える

問題のタイトルで検索したところ、これは Paillier 暗号と呼ばれる暗号化方式のようです。

Paillier 暗号は $n, c, r$ を公開し､ $n$ の素因数 $p, q$ を知っていれば復号することができます。具体的には、

$$(1+n)^m = 1+mn \pmod{n^2}$$

が成り立つので､ $(r^n)^\lambda = 1 \pmod{n^2}$ となる $\lambda$ を用いて
$$c^\lambda = (1+n)^{b\lambda} \cdot (r^n)^\lambda = (1+n)^{b\lambda} \pmod{n^2}$$

から平文 $b$ を求めることができます。

今回は $n, c$ のみが与えられているので､ $p, q$ が分かっても復号することはできません。

### 出現する符号から考える

今回は同じ文字は同じ符号に置き換えられ、フラグの形式は `"Alpaca{...}"` であることがわかっているので、これらの文字だけでフラグが構成されていればフラグを復元することができます。

```python
dic = {}
dic[cs[0]] = "A"
dic[cs[1]] = "l"
dic[cs[2]] = "p"
dic[cs[3]] = "a"
dic[cs[4]] = "c"
dic[cs[6]] = "{"
dic[cs[-1]] = "}"

print("".join(dic.get(c, "?") for c in cs))
# => Alpaca{????p????l??lp?c?????pl?c??}
```

まだまだ分からない文字が多いですね。

### 符号同士の関係から考える

Paillier 暗号の準同型性の説明を見ていると、`b` を暗号化した符号 $c_b$ は、`b+1` を暗号化した符号 $c_{b+1}$ と以下の関係を持ことに気づきました。

$$
\begin{align*}
c_{b+1} &= (1+n)^{b+1} r^n \\
&= (1+n) \cdot (1+n)^b r^n \\
&\equiv (1+n) \cdot c_b \pmod{n^2}
\end{align*}
$$

`"A"` を暗号化した符号が `cs[0]` であることが分かっているので、これを基準に `ord(c) - ord("A")` 回 $(1+n)$ を掛けることで、文字 `c` を暗号化した符号を求めることができます。

$(1+n)$ が $n^2$ と互いに素であることから､ $(1+n)$ は $\mathbb{Z}/n^2\mathbb{Z}$ で乗法の逆元を持つため、`"A"` より前の文字の符号も計算することができます。

```python
n2 = n * n
dic = {}
cA = cs[0]
for i in range(0x20, 0x7F):
    dic[(cA * pow(1 + n, i - ord("A"), n2)) % n2] = chr(i)

print("".join(dic.get(c, "?") for c in cs))
```

無事にフラグを復元することができました。

## 感想

アルパイエが何者なのか気になって先に Paillier 暗号の内容をカンニングしてしまいましたが、事前知識なしでも数式から十分解けるいい問題だと思いました。

結局アルパイエって何者？？

## 回答に使用したコード

- [solve.py](solve.py)

## 参考

- [Paillier暗号 - Wikipedia](https://ja.wikipedia.org/wiki/Paillier%E6%9A%97%E5%8F%B7)
