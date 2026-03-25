# glibc's secret function

https://alpacahack.com/daily/challenges/glibc-s-secret-function

## 問題の概要

入力した Flag が正しいかどうかを判定する ELF 形式のバイナリをリバースエンジニアリングし、正しい Flag を見つける Rev 問題です。

今回は初心者向けにソースコード main.c も提供されています。

処理の内容は次のような感じになっています。

- 111 文字の入力を受け取る
- `memfrob` 関数を適用
- 結果を `unsigned char expected[97]` と比較

## 解法

[`memfrob` 関数](https://man7.org/linux/man-pages/man3/memfrob.3.html) は、引数のバッファに対して XOR で 42 を適用することで内容を _暗号化_ するという GNU C 特有の関数です。

つまり、`expected` の各バイトに XOR 42 を適用すれば、正しい Flag を得ることができます。

今回のバイナリはシンボルテーブルが stripped されていないため、`expected` のアドレスは ELF ファイルから直接読み取ることができます。

```python
from pwn import *
elf = ELF("chal")

addr = elf.symbols["expected"]
expected = elf.data[addr : addr + 112]

decoded = [b ^ 42 for b in expected]
print(bytes(decoded))
```

無事に Flag を得ることができました。

`strfry` という関数もあるんですね...

`main.c` にはダミーのデータが入っているのだと思ってバイナリから読み出したのですが、ダミーフラグの内容も気になったので復元してみます。

```python
expected = [107, 70, 90, .....]
decoded = [b ^ 42 for b in expected]
print(bytes(decoded))
```

ダミーじゃなかった
