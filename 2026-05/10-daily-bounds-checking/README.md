# Bounds Checking

https://alpacahack.com/daily/challenges/bounds-checking

## 問題の概要

`win` 関数を呼び出せばフラグが出力される PWN 問題です。

`long index` と `long value` を `scanf` で読み取り、ローカル変数 `long array[0x100] = {}` に `array[index] = value` のように値を格納します。

ただし、`index >= 0x100` の場合は `puts("Too large index")` と表示されて終了します。

バイナリは No PIE で `win` 関数のアドレスは固定されています。

## 解法

`long index` は符号付整数ですが `index >= 0` のチェックが行われていないため、負の値を指定することができます。

しかしスタック上で `main` のリターンアドレスは `*array` より高位に配置されているため、書き換えるためには正の値を指定する必要があります。

No PIE でバイナリのアドレスは固定されていますが、スタックのアドレスは通常ランダム化されていて分かりません。したがって `*array` からの相対位置を確定できるのはスタック上の要素に限られ、GOT などの書き換えも難しそうです。

## アドレスをオーバーフローさせる

`array[index] = value` は `(uintptr_t)array + index * sizeof(long)` が指すアドレスに `value` を書き込むことを意味します。実際、アセンブリコードでは以下のようになっています。

```s
0x401395 <main+250>: mov    rax,QWORD PTR [rbp-0x820]  # index
0x40139c <main+257>: mov    rdx,QWORD PTR [rbp-0x818]  # value
0x4013a3 <main+264>: mov    QWORD PTR [rbp+rax*8-0x810],rdx
```

したがって、`index * 8` がオーバーフローするような巨大な負の数を `index` に入力すれば、境界チェックを回避して実質的に正のインデックスを指定することができます。

## 解答に使用したコード

リターンアドレスは `[rbp + 8]` にあるので、`[rbp + index * 8 - 0x810]` が `[rbp + 8]` を指すように `index` を計算します。

```python
index = (0x810 + 8) // 8
index |= 2**63  # 符号ビットを立てる
print(index - 2**64)  # 2 の補数表現での負の数として表示
# => -9223372036854775549

print(0x401236)  # win 関数のアドレス
# => 4198966
```

`index` と `value` をサーバーに送信すれば `win` 関数が呼び出されてフラグが得られます。

```bash
$ python3 gen_input.py | nc localhost 1337
```
