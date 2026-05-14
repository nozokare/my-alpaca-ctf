# Mirage

https://alpacahack.com/daily/challenges/mirage

## 問題の概要

フラグチェッカーが受け付ける正しいフラグを特定する REV 問題です。

一緒に配布されているソースコード `chal.c` を見ると、簡単な LFSR で生成した疑似乱数列と入力を XOR して暗号化した結果を、暗号化したフラグデータ `uint8_t enc[N]` と比較しています。

LFSR の状態遷移は以下のようになっています。

```c
uint16_t step(uint16_t s) {
    uint16_t bit = ((s >> 0) ^ (s >> 2) ^ (s >> 3) ^ (s >> 5)) & 1;
    return (s >> 1) | (bit << 15);
}
```

初期状態 `uint16_t state = 0xACE1` から `state = step(state)` を繰り返して疑似乱数列を生成し、各バイトが `((uint8_t)buf[i] ^ (state & 0x7F)) != enc[i]` のように比較されています。

## 解法

LFSR で生成した疑似乱数列と `enc[N]` を XOR して復号すれば正しいフラグが得られます。

## 解答に使用したコード

Python で `chal.c` と同じ LFSR を実装して復号しました。

```python
enc = [
    0x31, 0x54, 0x6c, 0x2f, 0x04, 0x52, 0x22, 0x41, 0x3f, 0x59,
    0x27, 0x45, 0x67, 0x79, 0x1a, 0x4e, 0x78, 0x2d, 0x19
]

def step(s):
    bit = ((s >> 0) ^ (s >> 2) ^ (s >> 3) ^ (s >> 5)) & 1
    return (s >> 1) | (bit << 15)

state = 0xACE1
buf = []
for e in enc:
    state = step(state)
    buf.append((state & 0x7F) ^ e)

print(bytes(buf).decode())
```
