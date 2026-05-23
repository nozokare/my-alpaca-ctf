# Conquer Ultimate Device Abyss

https://alpacahack.com/daily/challenges/conquer-ultimate-device-abyss

## 問題の概要

CUDA を使用したフラグチェッカーと、それを decompile したようなコードが与えられています。

main 関数で

- `d_A` に入力したフラグ(1 word = 4 byte の SIZE x SIZE の配列)
- `d_B` にグローバルで定義された配列 `long B[SIZE][SIZE] = {...}`
- `d_C` にグローバルで定義された配列 `long C[SIZE][SIZE] = {...}`

を読み込んで GPU に転送し、`compute` を呼び出しています。

```c
dim3 block(SIZE, SIZE);
dim3 grid(1, 1);
compute<<<grid, block>>>(12, d_A, d_B, 29, d_C);
```

CUDA カーネルは以下のようになっています。

```c
__global__ void compute(int a, int *b, long *c, int d, long *e)
{
    int f = threadIdx.y;
    int g = threadIdx.x;

    if (f < SIZE && g < SIZE)
    {
        long h = 0;
        for (int i = 0; i < SIZE; i++)
        {
            h += (long)b[f * SIZE + i] * c[i * SIZE + g];
        }
        e[f * SIZE + g] = (long)a * h + (long)d * e[f * SIZE + g];
    }
}
```

実行後の `d_C` と `long flag[SIZE][SIZE] = {...}` の内容が等しいとフラグが正しいと判断されます。

## 解法

見た感じ、`compute` は `E = a * B @ C + d * E` のような行列演算を計算しているようです。

呼び出しが `compute(12, d_A, d_B, 29, d_C)` なので、

`flag == 12 * A @ B + 29 * C` を `A` について解けばフラグが得られそうです。

整数行列として扱う必要があるので SageMath で計算してみます。

`long` の計算は正確には `Zmod(2**64)` 上ですが、`A` が 1 byte、`B` が 1 byte、`C` が 4 byte で mod が発生することがないので `ZZ` 上で計算します。

```sage
R = ZZ

flag = Matrix(R, [
  [0x0EE698DEA1B1, 0x0E9DD071A07B, 0x0C1924AC2E63, 0x0DB7C6567969],
  ...
])
B = Matrix(R, [
  [0xDE, 0xAD, 0xBE, 0xAF],
  ...
])
C = Matrix(R, [
  [0x61706C41, 0x61486163, 0x44206B63, 0x796C6961],
  ...
])

Y = (flag - 29 * C)
A = Y * (12 * B).inverse()
# =>
# [1634757697 1199268195 1598901573 1851880501]
# [1180660580 1197437488 1919249971 1298099297]
# [1769108577 1968004984 1885959276 1633905004]
# [1852795252 1700733217  895824185 2103731045]
```

`A` には入力したフラグが 1 word = 4 byte ずつ詰められるので、これをバイト列に変換すればフラグが得られました。

```sage
b''.join([int(a).to_bytes(4, byteorder='little') for a in A.list()])
```

---

`compute` の計算内容は general matrix multiplication と呼ばれる計算のようです。muladd の行列版のような感じでしょうか。
