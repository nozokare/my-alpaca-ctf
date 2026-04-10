# Linear Coffee Generator

https://alpacahack.com/daily/challenges/linear-coffee-generator

## 問題の概要

線型合同法ベースの疑似乱数生成器 `LCG` を用いて生成された乱数列から、内部パラメータを特定するとフラグを暗号化した鍵が得られる問題です。

`LCG` のパラメータは､ $p$ が 64 ビットのランダムな素数､ $a$, $b$, $s_0$ が 1 以上 $p$ 未満のランダムな整数です。

乱数列は以下の式で生成されます。

$$s_{i+1} = a \cdot s_i + b\ \mathrm{mod}\ p$$

($p$, $a$, $b$, $s_0$) を鍵としてAESで暗号化されたフラグと、$s_1$ ～ $s_4$ が与えられています。

## 解法を考える

得られている情報を式に起こしてみます。

$$
\begin{aligned}
s_1 &\equiv a s_0 + b \pmod{p} \\
s_2 &\equiv a s_1 + b \pmod{p} \\
s_3 &\equiv a s_2 + b \pmod{p} \\
s_4 &\equiv a s_3 + b \pmod{p}
\end{aligned}
$$

合同式が 4 本、未知変数が $p$, $a$, $b$, $s_0$ の 4 つなので解けそうな気がします。

まずは下3つの式の差を取って $b$ を消去してみます。

$$
\begin{aligned}
(s_3 - s_2) &\equiv a (s_2 - s_1) \pmod{p} \\
(s_4 - s_3) &\equiv a (s_3 - s_2) \pmod{p}
\end{aligned}
$$

$d_i = s_i - s_{i-1}$ とおくと

$$
\begin{aligned}
d_3 &\equiv a d_2 \pmod{p} \\
d_4 &\equiv a d_3 \equiv a^2 d_2 \pmod{p}
\end{aligned}
$$

です。合同式が 2 本、未知変数が $p$, $a$ の 2 つなのでこれも解けそうです。

いろいろ式をいじっているうちに、次のように $a$ を消去できることに気が付きました。

$$
\begin{aligned}
d_4 d_2 - d_3^2 &\equiv (a^2 d_2) d_2 - (a d_2)^2 \equiv 0 \pmod{p}
\end{aligned}
$$

$d_4 d_2 - d_3^2$ は $p$ の倍数になるので、0 でなければこれを素因数分解すれば $p$ の候補が得られます。

$p$ が分かれば、残りの未知変数は $\Z/p\Z$ での乗法の逆元を用いて

$$
\begin{aligned}
a &\equiv d_3 d_2^{-1} \pmod{p} \\
b &\equiv s_2 - a s_1 \pmod{p} \\
s_0 &\equiv (s_1 - b)\ a^{-1} \pmod{p}
\end{aligned}
$$

のように求められます。

## 計算

Python で実際に計算してみます。

```python
d2 = s2 - s1
d3 = s3 - s2
d4 = s4 - s3
d4 * d2 - d3 * d3
# => -18015186145068426177274734295463492132
```

0 ではなかったので、素因数分解すれば $p$ を得られそうです。

```python
from sympy import factorint
factorint(d3 * d3 - d4 * d2)
# => {2: 2, 9197623: 1, 37447334611: 1, 13076220846716751461: 1}
```

`13076220846716751461` が 64 ビットの素数なので、これが $p$ であると分かりました。

あとは残りの未知変数を求めて、用意されている `decrypt_flag` 関数に渡せばフラグが得られます。

```python
p = 13076220846716751461
a = d3 * pow(d2, -1, p) % p
b = (s2 - a * s1) % p
s0 = (s1 - b) * pow(a, -1, p) % p

decrypt_flag(flag_enc, (p, a, b, s0))
```

## 回答に使用したコード

- [solve.ipynb](solve.ipynb)
