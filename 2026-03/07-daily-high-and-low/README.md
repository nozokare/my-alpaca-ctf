# high and low

https://alpacahack.com/daily/challenges/high-and-low

## 問題の概要

Mersenne Twister の簡易版のような独自の乱数生成器から生成される乱数列について、次の数が high か low かを当てていく問題です。

`money` が `624` から始まり、正解/不正解で 1 ずつ増減し、`1337` まで増やせばフラグが出力されます。

RNG の実装は、内部状態が `N=624` 個の 32 ビット整数で構成されています。
`state[p]`, `state[(p+1) % N]`, `state[(p+397) % N]` を用いて次の状態 `x` を計算し、次のように temper して出力します。

```python
  .....
  self.state[p] = x
  self.p = q

  y = ((x >> 11) | ((x << 21) & 0xFFFFF800)) ^ 0xDEADBEEF
  return y
```

## 解法

temper の逆変換を行うことで、内部状態を復元できます。

```python
def untemper(y):
    x = y ^ 0xDEADBEEF
    return ((x << 11) & 0xFFFFFFFF | (x >> 21))
```

サーバーから `624` 個の乱数を受け取ると内部状態の全体を復元でき、次の乱数を予測できます。

## 回答に使用したコード

[solve.py](solve.py)
