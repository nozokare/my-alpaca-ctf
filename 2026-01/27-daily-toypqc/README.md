# ToyPQC

https://alpacahack.com/daily/challenges/toypqc

## 問題の概要

GF(p) 上でフラグにランダムな行列をかけてノイズを加えたものからフラグを復元する問題です。

- $p = 8380417$: 素数
- $A \in GF(p)^{10 \times 7}$: 各要素がランダムな行列
- $s \in GF(p)^7$: 21 文字のフラグを 3 バイトずつ整数に変換した 7 要素のベクトル
- $e \in GF(p)^{10}$: 各要素が 0 か 1 のランダムなノイズベクトル

$p$ は 3文字の ASCII 文字が表す最大の整数 `int.from_bytes(b"\x7f\x7f\x7f")` = 8355711 より大きく設定されています。

フラグを $GF(p)$ 上で次のように変換します。

$$ b = As + e $$

$A$, $b$ が与えられており､ $s$ を復元すればフラグが得られます。

## 解法

直感的には $p^7$ の情報を $A$ で $p^{10}$ に拡散することで多少のノイズを訂正できる符号のように見えます。

$\|As - b\|$ を最小化する $s$ を求めるか、全通りの $e$ で $As = b - e$ を解けば復元できそうです。

前者は $GF(p)$ 上での離散最適化問題になって解くのが難しそうです。
$e$ が取りうる値は $2^{10}$ 通りなので、後者の方法を試してみます。

SageMath で $GF(p)$ 上で $As = b - e$ の解が見つかる $e$ を全探索してみます。

```python
p = 8380417
F = GF(p)
A = matrix(F, [[ ... ]])
b = vector(F, [ ... ])

import itertools

for bits in itertools.product([0, 1], repeat=10):
    e = vector(F, bits)
    try:
        s = A.solve_right(b - e)
        print(s)
        break
    except:
        pass
# => (7561526, 6647092, 7628895, 6894943, 7681381, 6714673, 6184798)
```

1 通りの $e$ で解が見つかりました。これを文字列に直すと無事にフラグが得られました。

```python
b"".join([int(i).to_bytes(3) for i in s])
```
