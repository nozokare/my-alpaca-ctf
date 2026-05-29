# Safe Prime

https://alpacahack.com/daily/challenges/safe-prime

## 問題の概要

RSA 暗号でフラグが暗号化されていますが､ $q$ は安全素数、すなわち $q = 2p + 1$ で $p$ も素数であるような素数で､ $n = pq$ となっています｡

与えられているのは $n$ と $c$ で､ $e=65537$ も固定です。

## 解法

$n = pq = p(2p + 1) = 2p^2 + p$ なので､ $p$ は

$$2p^2 + p - n = 0$$

の正の解になります｡

$p$ がわかれば $q$ もわかるので､ $d$ を計算してフラグを復号できます｡

## 解答に使用したコード

- [solve.ipynb](./solve.ipynb)
