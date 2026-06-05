# Decrypt Shop

https://alpacahack.com/daily/challenges/decrypt-shop

## 問題の概要

サーバーに接続するとフラグ $m$ が RSA 暗号で暗号化され､ $n$, $e$, $c$ が与えられます｡

$$c = m^e\ \mathrm{mod}\ n$$

その後､ $c$ 以外の暗号文 $c'$ をサーバーに送ると先の暗号の復号鍵 $d$ を用いて復号した結果

$$m' = (c')^d\ \mathrm{mod}\ n$$

を返してくれます｡

## 解法

$c$ の代わりに $-c$ を送ると、復号結果として

$$(-c)^d = (-1)^d \cdot c^d \equiv -m \pmod{n}$$

が得られます。( $d$ は $(p-1)(q-1)$ と互いに素なので常に奇数です)

## 解答に使用したコード

```python
from pwn import remote
from Crypto.Util.number import long_to_bytes

conn = remote(host, int(port))

conn.recvuntil(b"n = ")
n = int(conn.recvline().strip())
conn.recvuntil(b"c = ")
c = int(conn.recvline().strip())

conn.sendlineafter(b"> ", str(n - c).encode())
m = int(conn.recvline().strip())
print(long_to_bytes(n - m))
```

## 感想

最近 $(\mathbb{Z}/n\mathbb{Z})^{\times}$ の構造に立ち入る機会が多くて解像度が上がってきたおかげかすんなり解くことができました｡

今回の問題は $(\mathbb{Z}/n\mathbb{Z})^{\times}$ の構造の強さが垣間見える問題で、人類が楕円曲線暗号に進んでいくのもなんとなくわかる気がします。
