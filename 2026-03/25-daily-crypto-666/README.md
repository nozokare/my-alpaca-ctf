# crypto_666

https://alpacahack.com/daily/challenges/crypto-666

## 問題の概要

10進数表記で "666...6" (666桁) を含む素数を入力するとフラグが得られる問題です。

## 解法

"666...6" の後ろに適当に "0" を付けた数から始めて順番に素数を探していけば良いです。

ちょっとした枝刈りとして、2 と 4 を交互に足していくことで 6n ± 1 の形の数だけを調べるようにします。

```python:solve.py
from Crypto.Util.number import isPrime

def find_prime_666(d: int) -> int:
    i = int("6" * 666 + "0" * d)
    i += 1 # 6n + 1
    while True:
        i += 4 # 6n - 1
        if isPrime(i):
            return i
        i += 2 # 6n + 1
        if isPrime(i):
            return i

print(find_prime_666(5))
```
