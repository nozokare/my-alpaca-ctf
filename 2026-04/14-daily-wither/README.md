# wither

https://alpacahack.com/daily/challenges/wither

## 問題の概要

フラグとランダムなバイト列との bitwise And を取った cipher が無限に得られます。

cipher の列からフラグを復元する問題です。

## 解法

十分な数の cipher を取得し、全体の bitwise Or をとるとフラグに収束します。

なぜなら、`flag`, `cipher` の $i$ 番目のビットをそれぞれ $P_i$, $C_i$ とすると、

- 確率 1/2 で $C_i = P_i \texttt{\\&} 0 = 0$
- 確率 1/2 で $C_i = P_i \texttt{\\&} 1 = P_i$

になります。

$n$ 個の cipher を取得したとき、各 chiper の $i$ 番目のビット $C_i^{(1)}, C_i^{(2)}, \ldots, C_i^{(n)}$ が全て $P_i \texttt{\\&} 0$ である確率は $1/2^n$ です。

したがって、十分な数の cipher を取得すれば高い確率でどれかは $P_i \texttt{\\&} 1$ を含むことになり、このとき

$$P_i = C_i^{(1)}\ |\ C_i^{(2)}\ |\ \cdots\ |\ C_i^{(n)}$$

で $P_i$ を得ることができます。

## 回答に使用したコード

```python
from pwn import remote

conn = remote(host, port)

def Or(a, b):
    return bytes([x | y for x, y in zip(a, b)])

def get_cipher():
    conn.sendline()
    conn.recvuntil(": ")
    return bytes.fromhex(conn.recvline().decode().strip())

flag = get_cipher()
for _ in range(10):
    flag = Or(flag, get_cipher())
    print(flag)
```
