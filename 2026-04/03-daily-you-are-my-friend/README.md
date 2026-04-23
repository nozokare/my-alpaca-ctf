# You are my friend

https://alpacahack.com/daily/challenges/you-are-my-friend

## 問題の概要

次のように暗号化されたフラグを復号する問題です。

```python
import secrets

def rot13_char(c):
    if 'a' <= c <= 'z':
        return chr((ord(c) - ord('a') + 13) % 26 + ord('a'))
    if 'A' <= c <= 'Z':
        return chr((ord(c) - ord('A') + 13) % 26 + ord('A'))
    return c

def rot13(text):
    return ''.join(rot13_char(c) for c in text)

flag = "Alpaca{REDACTED}"

ct = rot13(flag)

key = secrets.randbelow(256)
cts = [ord(ct[0]) ^ key]
for i in range(1, len(ct)):
    cts.append(ord(ct[i]) ^ ord(ct[i - 1]))

print(cts)
```

## 解法

暗号化の処理はだいたい次のようになっています。

```
ct[i] = Rot13(flag[i])  (0 ≤ i < n)
cts[0] = ct[0] ⊕ key
cts[i] = ct[i] ⊕ ct[i-1]  (0 < i < n)
```

`Rot13` はアルファベットを13文字ずらす写像で、`Rot13` の逆写像も `Rot13` になります。
復号する手順を解くと、次のようになります。

```
ct[0] = cts[0] ⊕ key
ct[i] = cts[i] ⊕ ct[i-1]  (0 < i < n)
flag[i] = Rot13(ct[i])  (0 ≤ i < n)
```

`key` は 0 から 255 までの整数なので、全パターンを試してもよいですし、
フラグの1文字目が `"A"` であることがわかっているので直接 `ct[0]` を求めることもできます。

## 解答に使用したコード

```python
ct = [0] * len(cts)
ct[0] = ord(rot13_char("A"))
for i in range(1, len(cts)):
    ct[i] = cts[i] ^ ct[i - 1]

flag = [rot13_char(chr(c)) for c in ct]
print("".join(flag))
```

全文は [decrypt.py](decrypt.py) にあります。
