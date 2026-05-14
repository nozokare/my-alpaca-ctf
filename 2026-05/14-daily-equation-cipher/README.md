# Equation Cipher

https://alpacahack.com/daily/challenges/equation-cipher

## 問題の概要

SageMath で多項式

$$
\begin{aligned}
f(x) &= \prod_{i} (p_i x - c_i)\\
     &= (2x - \mathtt{ord("A")})(3x - \mathtt{ord("l")})(5x - \mathtt{ord("p")}) \cdots
\end{aligned}
$$

を展開したものが与えられています。( $p_i$ は $i$ 番目の素数､ $c_i$ はフラグの $i$ 文字目のコードです)

## 解法1: f を素因数分解する

SageMath で与えられた多項式を因数分解すれば $(2x-c_0)(3x-c_1)(5x-c_2)\cdots$ の形が得られます。
(係数環を $\Z$ にすれば係数は整数に制限されます)

```sage
R.<x> = PolynomialRing(ZZ, 'x')
with open("output.txt") as file:
    f = sage_eval(file.read(), locals={"x": x})

factor(f)
# => 3 * 11 * (x - 36) * (x - 9) * (2*x - 65) * (5*x - 112) * (7*x - 97) ...
```

$p=3$ と $p=11$ の項が $c_i$ と共通の因数を持って外に出ていますが、`ord(c)` の範囲的に `(3*x - 3*36)` と `(11*x - 11*9)` だったと考えられます。

フラグの長さは $\deg(f)=30$ 文字なので、このくらいなら手動で $c_i$ を並べてもフラグを復元できますが、できれば機械的に処理したいところです。

## 解法2: 範囲内の根を探す

$i$ 番目の項が $(p_i x - c_i)$ だったなら $f(c_i/p_i) = 0$ になります。

したがって $p_i$ に対して $f(c_i/p_i)=0$ になる $c_i$ を全探索すれば機械的にフラグを復元できます。

```sage
import string
for p in prime_range(200):
  for c in "{}_" + string.ascii_letters:
    if f(ord(c)/p) == 0:
      print(c, end="")
      break
  else:
    print("¿", end="")
# => Alpaca{*************}¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
```

Python 標準ライブラリでも任意精度の有理数を扱えるので SageMath を使わずに解くこともできます。

- [solve.py](solve.py)

## 雑談

最近 VSCode で Jupyter Notebook を開いて Kernel を選択すると SageMath の Docker コンテナを起動して ipykernel に接続する仕組みを整えたので、さっそく活用できてよかったです。

開いている .ipynb ファイルを置いているディレクトリを自動でマウントしてくれるので、かなりシームレスに SageMath を使えて便利になりました。

わりと頻繁に使うのでベース環境に直接入れてしまってもよさそうですが、全部詰め込むとごちゃごちゃになるのが難しいところ…

AI のおかげで少々複雑なことも楽にできるようになったので、いい感じに環境を育てていきたいですね。
