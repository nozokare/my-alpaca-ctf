# Haec Horrenda

## 問題の概要

`echo` コマンドに渡したときに条件を満たす出力になる文字列を答える問題です。

## Round1

`/usr/bin/echo` に渡したときに次の文字を出力する文字列を答えます。

- `-e\n`
- `--version\n`

### 解答

`/usr/bin/echo` は GNU coreutils のコマンドです。

そのまま `/usr/bin/echo -e` や `/usr/bin/echo --version` とすると `-e` オプションや `--version` オプションと解釈されてしまいます。

`-- -e` のようにしても `echo` は `--` をオプションの終了と解釈せず、単純に `-- -e` を出力してしまいます。

[ドキュメント](https://www.gnu.org/savannah-checkouts/gnu/coreutils/manual/html_node/echo-invocation.html) を見ると、`-e` オプションが有効な場合、次の形式の文字を解釈することができます。

```
‘\0nnn’
    the eight-bit value that is the octal number nnn (zero to three octal digits), if nnn is a nine-bit value, the ninth bit is ignored

‘\nnn’
    the eight-bit value that is the octal number nnn (one to three octal digits), if nnn is a nine-bit value, the ninth bit is ignored

‘\xhh’
    the eight-bit value that is the hexadecimal number hh (one or two hexadecimal digits)
```

このため、`-` を　`\x2d` として表現することで、`-e` を出力することができます。

また、`--version` フラグは他フラグと併用できないため、`-e --version` とすることで、`--version` を出力することができます。

### 解答に使用した入力

```text
-e \x2de
-e --version
```

## Round2

`/usr/bin/echo -e {input}` の形で渡したときに、長さが 0, 1, ..., 8 文字になるような文字列を答えます。

ただし、入力は8文字の印字可能な ASCII 文字でなければいけません(`[\x21-\x7E]{8}`)。つまり、空白文字も使用できないため、複数の引数を渡すことができません。

### 解答

`\xhh` や `\nnn` 形式のエスケープシーケンスを使用すれば、3～8文字の出力は簡単に実現できます。

0 文字の出力は、`-eeennnn` のように同じオプションを複数回指定し、`\n` を出力させないことで実現できました。
1 文字の出力は、`-eeeeeee` のようにすれば `\n` だけが出力されます。

問題は 2 文字の出力の場合です。ドキュメントを見直すと、それ以降の文字の出力を抑制する `\c` というエスケープシーケンスがあることが分かりました。全部これでええやん

### 解答に使用した入力

```text
-eeennnn
-eeeeeee
22\c2222
\x33\x33
\4\44\44
55\55\55
6666\666
77777\77
888888\\
```

## Round3

次の 3 種類の `echo` を呼びだします。

- `/usr/bin/echo` (GNU coreutils)
- `bash` の組み込み `echo`
- `zsh` の組み込み `echo`

このとき、{GNU, bash, zsh} の出力だけが {長く, 短く} なるような文字列を答えます。(全6パターン)

### 解答

`man echo` と `man bash` と `man zshbuiltins` を見比べると、若干差があることが分かります。

Bash と zsh は unicode エスケープシーケンス `\uHHHH` と `\UHHHHHHHH` をサポートしていますが、GNU はサポートしていません。

```
[\x20-\x7E]+: -e \u0
bash: b'\x00\n'(2)
zsh: b'\x00\n'(2)
gnu: b'\\u0\n'(4)
|bash| = |zsh| < |gnu|
```

`\nnn` 形式のエスケープシーケンスを使用できるのは GNU だけです。

```
[\x20-\x7E]+: -e \2
bash: b'\\2\n'(3)
zsh: b'\\2\n'(3)
gnu: b'\x02\n'(2)
|bash| = |zsh| > |gnu|
```

Bashのみ `\E` をエスケープシーケンスとして解釈します。

```
[\x20-\x7E]+: -e \E
bash: b'\x1b\n'(2)
zsh: b'\\E\n'(3)
gnu: b'\\E\n'(3)
|zsh| = |gnu| > |bash|
```

いろいろ試したところ、zsh だけが `\u` を `\u0000` として解釈するようです。

```
[\x20-\x7E]+: -e \u
bash: b'\\u\n'(3)
zsh: b'\x00\n'(2)
gnu: b'\\u\n'(3)
|gnu| = |bash| > |zsh|
```

これらを組み合わせることで、全6パターンを実現できます。

### 解答に使用した入力

```
-e \u0
-e \2
-e \2\u
-e \E
-e \2\E
-e \u
```
