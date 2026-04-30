# multi-xor

https://alpacahack.com/daily/challenges/multi-xor

## 解法

`FLAG` ↦ `cipher_f, cipher_g` は見た感じ GF(2)-線型写像で、`combined_is_unique` で表現行列 $A$ が Full Rank なことが保証されていそうです。

表現行列 $A$ を求めて線型方程式を解けば `FLAG` が得られます。

大味な解法ですが、GF(2)-線型写像なら細かい処理を調べなくても解けるので丸投げしちゃいます。

## 解答に使用したコード

```sage
from chall import xor_bytes, f, g

def F(x: bytes) -> bytes:
    for i in range(R):
        x = f(x)
        x = xor_bytes(x, f_keys[i])
    return x

def G(x: bytes) -> bytes:
    for i in range(R):
        x = g(x)
        x = xor_bytes(x, g_keys[i])
    return x

GF2 = GF(2)

def bytes_to_gf2(b: bytes) -> vector:
    bits = [(byte >> j) & 1 for byte in b for j in range(8)]
    return vector(GF2, flatten(bits))

def gf2_to_bytes(v) -> bytes:
    bits = [v[i : i + 8] for i in range(0, len(v), 8)]
    return bytes([int(ZZ(list(bits), base=2)) for bits in bits])

def get_matrix(func, dim):
    A = []
    for i in range(dim):
        input_vector = gf2_to_bytes(vector(GF2, [0 if j != i else 1 for j in range(dim)]))
        output_vector = bytes_to_gf2(func(input_vector))
        A.append(output_vector)
    return matrix(GF2, A).T

A = get_matrix(lambda x: F(x) + G(x), n * 8)
y = bytes_to_gf2(cipher_f + cipher_g)
x = A.solve_right(y)
gf2_to_bytes(x)
```

numpy + galois をよく使っていたのですが、`numpy.linalg.solve` は $A$ が正方行列でないと使えなくて不便なので SageMath を使ってみました。
`solve_right` は $A$ が正方行列でなくても解けるので便利です。
