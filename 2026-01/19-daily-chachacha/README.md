# ChaChaCha

https://alpacahack.com/daily/challenges/chachacha

## 問題の概要

ChaCha20 で同じ key と nonce を使って flag と既知のテキスト msg をそれぞれ暗号化した結果が与えられています。

## 解法

調べたところ、ChaCha20 は平文と疑似乱数列の XOR を取ることで暗号化するストリーム暗号であることが分かりました。

今回は同じ key と nonce を使っているため疑似乱数列も同じになります。

したがって msg の平文と暗号文から疑似乱数列を求め、flag の暗号文と XOR することで flag の平文を求めることができます。

## 解答に使用したコード

```python
from pwn import xor

with open("handout/output.txt", "r") as f:
    msg_enc = bytes.fromhex(f.readline().split(":")[1])
    flag_enc = bytes.fromhex(f.readline().split(":")[1])

msg = b"Daily AlpacaHack is a daily CTF challenge with a fun new puzzle every day."

key = xor(msg_enc, msg)
flag = xor(flag_enc, key)
print(flag)
```
