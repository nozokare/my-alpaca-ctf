# Erased Secret

https://alpacahack.com/daily/challenges/erased-secret

## 問題の概要

ランダムな `secret` の内容を当てるとフラグが表示される PWN 問題です。

まず、`prepare()` 関数で次のような処理が行われます。

- ローカル変数 `unsigned char secret[32]` にランダムな HEX 文字列を読み込む
- `SHA256` 関数で `secret` のハッシュを計算し、グローバル変数 `target_hash[]` に格納する
- `memset` 関数で `secret` の内容を上書きして消去する

次に `challenge()` 関数で次のような処理が行われます。

- `'?'` を入力すると、指定した `i` について、ローカル変数 `unsigned char mem[0x100]` の `mem[i]` の値を出力する (何回でも可能)
- `'!'` を入力すると、`fgets` で読み込んだ文字列のハッシュを計算し、`target_hash` と比較する

ハッシュ値が一致した場合、`win` 関数が呼び出されてフラグが表示されます。

### バイナリ情報

```
$ checksec ./chal
  Arch:       amd64-64-little
  RELRO:      Full RELRO
  Stack:      Canary found
  NX:         NX enabled
  PIE:        PIE enabled
  FORTIFY:    Enabled
  SHSTK:      Enabled
  IBT:        Enabled
  Stripped:   No
```

## 問題を分析する

`checksec` で初めて見る `FORTIFY: Enabled` という項目がありました。調べたところ、これは `glibc` のセキュリティ機能の一つで、バッファオーバーフローの検出を強化するものだそうです。

文字列の読み込みも `fgets` を使用していて BOF の余地がなく、無理やり `win` を実行する ROP 問題ではなく、`secret` の内容を当てて正規のルートで `win` を呼び出す問題だと理解できます。

## 解法

`prepare` 関数と `challenge` 関数は使用するスタック領域が重なっているため、`challenge` 関数内のローカル変数 `unsigned char mem[0x100]` を通して `prepare` 関数実行時のローカル領域の内容を読み取ることができます。

`secret` の内容は上書きされてしまっていますが、ハッシュ値を計算する過程でどこかにコピーされている可能性があります。

pwndbg で `secret` を上書きする直前の `secret` の内容を確認し、`search` コマンドでどこかに同じ内容がないか探してます。

……と思ったのですが、`prepare` 関数のアセンブリを確認すると、最後の `memset` 処理が見当たりませんでした。

ローカル変数 `secret` の内容を関数の終了前に変更してもその後に参照されることがないため、コンパイラの最適化によって消されてしまったようです。

## アドレスを調べる

pwndbg で `secret[]` と `mem[]` のアドレスを調べます。

`secret[]` のアドレスは `prepare` 関数の `SHA256` の呼び出し時に引数を確認するのが分かりやすいです。

`mem[]` のアドレスは、`i` = 0 として challenge 関数の `printf("mem[%zu] = 0x%02x\n", i, mem[i])` の呼び出し前に `mem[i]` の値を読み出す部分を確認します。

```bash
$ pwndbg ./chal
pwndbg> break *prepare+203
pwndbg> break *challenge+226
pwndbg> run

...
 ► 0x55555555544b <prepare+203>    call   SHA256@plt                  <SHA256@plt>
        d: 0x7fffffffd640 ◂— '167400eb90004d84c2c82c25b4d6c03a'
        n: 0x20
        md: 0x555555558060 (target_hash) ◂— 0
...

pwndbg> continue
Continuing.
hash: 566f888daa6cd1cff6cef6e9655bea47bd6e7060aaff4f0340a8ce2357a8df6a
`?` for check, `!` for answer.
choice: ?
index: 0

...
 ► 0x555555555612 <challenge+226>    movzx  ecx, byte ptr [rbp + rdx - 0x130]     ECX, [0x7fffffffd560] => 0x70
   0x55555555561a <challenge+234>    call   __printf_chk@plt            <__printf_chk@plt>
...
```

`secret[]` のアドレスは `0x7fffffffd640` で、`mem[]` のアドレスは `0x7fffffffd560` であることが分かりました。

したがって、`mem[0xE0]` から32バイトを読み取ることで `secret` の内容を得ることができます。

## 解答に使用したコード

- [solve.py](solve.py)

## 安全にメモリを消去するには

`secret` の内容を `memset` で上書きする方法は、今回のようにコンパイラの最適化によって消されてしまう可能性があります。

今回の問題のフラグで、安全にメモリを消去する関数が紹介されていました。

- [C11 の `memset_s` 関数](https://en.cppreference.com/w/c/string/byte/memset.html)
- [OpenBSD の `explicit_bzero` 関数](https://man.freebsd.org/cgi/man.cgi?query=explicit_bzero)
- [Windows の `SecureZeroMemory` 関数](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-securezeromemory)

これらの関数はメモリ書き込みを確実に行うために最適化で消されないように設計されているそうです。
