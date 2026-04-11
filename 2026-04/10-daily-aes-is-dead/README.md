# AES is dead

https://alpacahack.com/daily/challenges/aes-is-dead

## 問題の概要

Python Pillow でフラグのテキストを描画した BMP 画像を AES-ECB で暗号化したファイル `flag.enc` からフラグを復元する問題です。

## 解法

BMP 画像は各ピクセルを表すバイト列をそのまま並べたような形式で保存されています。

ECB モードの AES では同じ平文ブロックは同じ暗号文ブロックに変換されるため、元画像の各ピクセルに対応する暗号文のバイト列を元の画像と同じ位置にプロットすると、元の画像のパターンが浮かび上がります。

### 元の画像のサイズを求める

BMP 画像のフォーマットを調べたところ、14+40 バイトのヘッダの後に左下→右上の順にピクセルを表すバイト列を並べ、各行のデータが 4 バイト単位になるようにパディングされているそうです。

例として、配布されている `chall.py` で `flag.bmp` を保存するところまで実行し、画像のフォーマットを確認してみます。

```bash
$ file flag.bmp
flag.bmp: PC bitmap, Windows 3.x format, 1293 x 124 x 24, image size 481120, resolution 3780 x 3780 px/m, cbSize 481174, bits offset 54
```

ヘッダが 54 バイト、各ピクセルが 3 バイトで、各行のデータがパディングを含めて 3×1293+1=3880 バイト、画像データが 3880×124=481120 バイト、のような内訳になっています。

AES-ECB で暗号化するときに 16 バイトのブロック単位で暗号化するためにさらに PKCS#7 のパディングが追加され、これが暗号化後のファイルのサイズになります。

$$
\begin{aligned}
\texttt{flag\_enc} &= \texttt{header} + 4\ell \times h + \texttt{aes\_pad}\\
4\ell &= 3 \times w + \texttt{line\_pad}
\end{aligned}
$$

`flag.enc` のサイズから、考えうる元画像のサイズ $w \times h$ とパディングの長さを探ってみます。

```python
from sympy import factorint
header_len = 14 + 40
possible_pad_lens = [2, 6, 10, 14]
for pad_len in possible_pad_lens:
    image_size = len(data) - header_len - pad_len
    print(f"{pad_len}: factors: {factorint(image_size)}, 124x{image_size//124} + {image_size%124}")
# =>
# 2: factors: {2: 3, 23: 1, 4801: 1}, 124x7124 + 8
# 6: factors: {2: 2, 3: 1, 5: 1, 14723: 1}, 124x7124 + 4
# 10: factors: {2: 4, 13: 1, 31: 1, 137: 1}, 124x7124 + 0
# 14: factors: {2: 2, 7: 2, 4507: 1}, 124x7123 + 120
```

$4\ell \times h$ にあてはまる因数分解のパターンを全て試せばどれかが元の画像に一致するはずです。

今回はダミーフラグを描画した `flag.bmp` の高さが 124 だっだので、まずは AES のパディングが 10 バイトで、各行 7124 バイト × 高さ 124 の場合を試してみます。

### 画像の復元

元画像は (3 × 2374 = 7122 バイトのピクセルデータ + 2 バイトの行パディング) × 124 行 で構成されていることになります。

行パディングを取り除いて 3 バイトずつ RGB の値を詰めなおしてもよいですが、今回はパターンが浮かび上がればいいだけなので、雑に 1 ピクセル 4 バイト単位で解釈してプロットします。

```python
from PIL import Image
Image.frombytes("RGBA", (7124 // 4, 124), data[header_len:]).transpose(Image.FLIP_TOP_BOTTOM)
```

色は無茶苦茶ですが元画像で白/黒で塗分けられていた領域のパターンがはっきり現れ、フラグのテキストが読み取れました。

## 回答に使用したコード

- [solve.ipynb](solve.ipynb)
