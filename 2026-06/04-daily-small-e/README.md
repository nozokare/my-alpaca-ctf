# Small e

https://alpacahack.com/daily/challenges/small-e

## 問題の概要

シンプルな RSA 暗号でフラグが暗号化されています。ただし､ $e=5$ と小さいです。

$p$, $q$ ～ 1024 ビットに対して `len(FLAG) < 50` 程度の大きさです。

## 解法

$m$ が 50×8 = 400 ビット程度なので､ $m^5$ ～ 2000 ビット程度で $n$ ～ 2048 ビット程度より小さくなります。

したがって、`c = pow(m, 5, n)` は mod が発生せず、`pow(c, 1/e)` を計算すればフラグが得られます。

## 解答に使用したコード

Python だと精度の問題で計算できないので SageMath を使用しました。

```sage
m = pow(c, 1 / e)
print(bytes.fromhex(hex(m)[2:]))
```
