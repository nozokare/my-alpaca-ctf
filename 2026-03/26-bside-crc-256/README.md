# CRC-256

https://alpacahack.com/daily-bside/challenges/crc-256

## 問題の概要

CRC ハッシュを衝突させる問題です。

サーバーで CRC ベースのハッシュ関数が定義されており、提示されたハッシュ値と同じハッシュ値を持つ入力を答えるとフラグが得られます。

入力は 1 ～ 512 文字の英数字に制限されています。

ハッシュの計算は次のように定義されています。

```python
def pack(n):
    return n.to_bytes(0 - -n.bit_length() // 8, "little")


def crc(m, g):
    k = g.bit_length() - 1
    m += pack(len(m))
    m = int.from_bytes(m, "big") << k
    r = 0
    for i in range(m.bit_length())[::-1]:
        r <<= 1
        r |= m >> i & 1
        if r >> k & 1:
            r ^= g

    return r ^ ~(~0 << k)
```

生成多項式は練習用に G32、本題では G256 が使われ、2 回とも回答できるとフラグが得られます。

```python
G32 = 0x104C11DB7
G256 = 0x188B44516A21A416237491AA8F4FA81FA64FCE3FB30CC64D9F8F3864910C71ADF
```

## ハッシュ関数の理解

通常の CRC ハッシュ関数は入力メッセージのビット列を GF(2) 上の多項式 $m(x) \in \mathbb{F}_2[x]$ とみなし、生成多項式 $g(x)$ の次数 $k$ 分だけ左にシフトした $m(x) \cdot x^k$ を $g(x)$ で割った余り $r(x)$ をハッシュ値とします。

問題の実装では、入力の最後に長さをエンコードして付加し、余りをビット反転した値を返すようになっています。
pack された長さを $p(x)$ 、長さのビット数(8bit aligned)を $l$ とすると、ハッシュ値は次のように表せます。

$$
\overline{r(x)} = (m(x) \cdot x^l + p(x)) \cdot x^k \mod g(x)
$$

$p(x)$ が非線形項になるため、通常の CRC の線型性はそのままでは成り立ちません。

例えば、同じ長さの入力 $m_1$ と $m_2$ で $\mathrm{crc}(m_1) \oplus \mathrm{crc}(m_2)$ を計算すると､ $p(x)$ の部分同士は XOR されないため

$$
\mathrm{crc}(m_1 \oplus m_2) = \mathrm{crc}(m_1) \oplus \mathrm{crc}(m_2) \oplus P_l\\
(P_l = p(x) \cdot x^k \operatorname{mod} g(x))
$$

のようになります。

## 解法の方針

メッセージの長さを固定すれば、メッセージの特定のビットを反転させたときにハッシュ値のどのビットが反転するかを計算できます。

具体的には､ $e_i(x) = x^i$ とすると､ $$r_i = e_i(x) \cdot x^{l+k} \operatorname{mod} g(x)$$ を計算すれば

$$
\mathrm{crc}(m \oplus e_i) = \mathrm{crc}(m) \oplus r_i
$$

となります。

したがって、ターゲットのハッシュ値を $c_0$ とし、長さ $l$ ビットの初期メッセージ $m_1$ を適当にえらんで $c_1 = \mathrm{crc}(m_1)$ としたとき、

$$
c_1 \oplus c_0 = \bigoplus_{i \in S} r_i
$$

となるような $S \subseteq \{0, \ldots, l-1\}$ を見つければ､ $$\mathrm{crc}(m_1 \oplus \bigoplus_{i \in S} e_i) = c_0$$ となる解が得られます。

## 問題を方程式化する

$r_i$ を列ベクトルとする行列 $A \in GF(2)^{k \times l}$ を考えると、上の式は GF(2) 上の線形方程式 $$A x = c_1 \oplus c_0$$ として表せます。

ただし、解が英数字のビット列になるようにする必要があるため、自由度をもたせるビットを制限する必要があります。

ASCII コード表とにらめっこしながらビットを反転させても英数字の範囲に収まるマスクを探してみます。

```python
for i in range(256):
    if i & 0b1101_0001 == 0b0100_0001:
        print(chr(i), end="")
# => ACEGIKMOacegikmo
```

`'A'` の 1, 2, 3, 5 ビット目を反転させても英数字の範囲に収まることがわかります。

## 行列の探索

反転可能なビット位置に対応する $r_i$ を計算し、線型独立なものを追加していく形でフルランクの正方行列 $A$ を構築します。

GF(2) 上の演算は [galois](https://mhostetter.github.io/galois/latest/) を使用しています。

```python
def search_matrix(G: int):
    k = G.bit_length() - 1
    # 自由度が足りるまで m1 = "A" * L の長さを増やす
    for L in range(k // 4, k):
        l = L.bit_length() + (-L.bit_length() % 8)  # 付加される長さのビット数
        A_cols = []
        index = []
        for i in range(L * 8):
            # 自由度のないビットはスキップ
            if (1 << i % 8) & 0b1101_0001:
                continue

            # r_i を計算
            e_i = 1 << (k + l + i)
            r_i = gf2mod(e_i, G)
            r_i_vec = [(r_i >> j) & 1 for j in range(k)]

            # 線型独立な列が見つかったら追加
            if is_linearly_independent(A_cols + [r_i_vec]):
                A_cols.append(r_i_vec)
                index.append(i)

        if len(A_cols) == k:
            A = GF2(np.stack(A_cols, axis=1))
            return A, index, L

    raise ValueError("no solution found")


def is_linearly_independent(vectors):
    matrix = GF2(np.stack(vectors, axis=1))
    return np.linalg.matrix_rank(matrix) == len(vectors)
```

G32 用の行列は `L=8` で、G256 用の行列は `L=65` で見つかりました。

## 衝突するメッセージを求める

$m_1$ = `"AAA...A"` (長さL) の CRC値 $c_1$ を計算し、方程式 $A x = c_1 \oplus c_0$ を解いて $x$ を求めます。

解に対応するビットを反転させると衝突するメッセージが得られます。

```python
def solve(c0: int, G: int) -> bytes:
    k = G.bit_length() - 1
    A, index, L = search_matrix(G)
    print(f"A: A{A.shape}, L: {L}")

    m1 = "A" * L  # ベースとなるメッセージ
    c1 = crc(m1.encode(), G)  # ベースとなるCRC値

    target = GF2([(c1 ^ c0) >> i & 1 for i in range(k)])
    x = np.linalg.solve(A, target)
    m1_int = int.from_bytes(m1.encode(), "big")
    for i, flip in zip(index, x):
        if flip:
            m1_int ^= 1 << i
    return m1_int.to_bytes(L, "big")
```

次のように衝突するメッセージを求めることができました。

```
target sum: 0x8E92DAFF
A: A(32, 32), L: 8
m1: b'KOgmMIim' c1: 0x8E92DAFF
target sum: 0xA72DFF5A0C07A80711554048F356627C91879924AB1CA5FF3152ADE717CD7D2E
A: A(256, 256), L: 65
m1: b'EKGoEOkKeICcmAomIigeoggmOIcOcakokMEKIakIkmkEIOaoEkgGoImekKaMcCAEe' c1: 0xA72DFF5A0C07A80711554048F356627C91879924AB1CA5FF3152ADE717CD7D2E
```

## 回答に使用したコード

- [crc.py](./crc.py)
- [solve.py](./solve.py)
