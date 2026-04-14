# flag obfuscation

https://alpacahack.com/daily/challenges/flag-obfuscation

## 問題の概要

`obfuscator.c` でフラグチェッカーのバイナリを変換した結果 `data.h` が与えられています。

`obfuscator.c` は、入力を 16 バイト単位で IPv6 アドレスとして解釈し、IPv6 アドレスの文字列の配列を宣言する次のような `data.h` を生成します。

```h
char *ipv6_data[] = {
"4d5a:9000:300:0:400:0:ffff:0",
"b800::4000:0:0:0",
"::",
...
};
int ipv6_count = 2464;
```

フラグチェッカーを復元し、正しいフラグを見つける問題です。

## 解法

まずはフラグチェッカーのバイナリを復元します。

```python
import ipaddress

chunks = []
with open("data.h") as f:
    f.readline()
    while (line := f.readline()).startswith('"'):
        addr = ipaddress.IPv6Address(line.strip()[1:-2])
        chunks.append(addr.packed)

with open("chal", "wb") as f:
    for chunk in chunks:
        f.write(chunk)
```

復元したバイナリを確認してみます。

```bash
$ file chal
chal: PE32+ executable for MS Windows 5.02 (console), x86-64 (stripped to external PDB), 10 sections
```

内容は x86-64 の Windows の実行ファイルでした。

フラグの文字列があるかを確認してみます。

```bash
$ strings chal | grep "Alpaca"
Alpaca{iH
```

断片的にしか見つからなかったので、radare2 で解析してみます。

strip されているため `main` 関数にあたる部分を見つける必要があります。
Windows 実行ファイルのエントリポイント `entry0` から辿ろうとすると処理が複雑で大変だったので、文字列の参照から `main` 関数を見つけることにしました。

```bash
$ r2 -A chal
.....
[0x1400014f0]> iz  # data section の文字列を確認
nth paddr      vaddr       len size section type    string
――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
0   0x00007200 0x140009000 12  13   .rdata  ascii   Input flag:
1   0x0000720d 0x14000900d 6   7    .rdata  ascii   Wrong\n
2   0x00007214 0x140009014 9   10   .rdata  ascii   Correct!\n
3   0x00007280 0x140009080 13  14   .rdata  ascii   Unknown error
4   0x00007290 0x140009090 30  31   .rdata  ascii   Argument domain error (DOMAIN)
.....
[0x1400014f0]> axt 0x140009000  # "Input flag:" を参照しているコードを確認
fcn.1400079e0 0x140007a06 [STRN:r--] lea rcx, str.Input_flag:

[0x1400014f0]> s fcn.1400079e0  # 見つかった関数に移動
[0x1400079e0]> pdf # disassemble
            ; CALL XREF from fcn.140001190 @ 0x1400013bf(x)
┌ 208: fcn.1400079e0 ();
│ afv: vars(9:sp[0x70..0xa1])
│           0x1400079e0      53             push rbx
│           0x1400079e1      4881ec9000..   sub rsp, 0x90
│           0x1400079e8      e8639cffff     call fcn.140001650
│           0x1400079ed      488d5c2450     lea rbx, [var_50h]
│           0x1400079f2      c644244c00     mov byte [var_4ch], 0
│           0x1400079f7      48b8416c70..   movabs rax, 0x697b616361706c41 ; 'Alpaca{i'
│           0x140007a01      4889442420     mov qword [var_20h], rax
│           0x140007a06      488d0df315..   lea rcx, str.Input_flag:   ; section..rdata
│                                                                      ; 0x140009000 ; "Input flag:" ; int64_t arg1
│           0x140007a0d      48ba707636..   movabs rdx, 0x7566626f5f367670 ; 'pv6_****'
│           0x140007a17      48b8736361..   movabs rax, 0x5f6e6f6974616373 ; '********'
│           0x140007a21      4889542428     mov qword [var_28h], rdx
│           0x140007a26      48ba63616e..   movabs rdx, 0x646176655f6e6163 ; '********' ; int64_t arg2
│           0x140007a30      4889442430     mov qword [var_30h], rax
│           0x140007a35      48b8655f73..   movabs rax, 0x74616e6769735f65 ; '********'
│           0x140007a3f      4889542438     mov qword [var_38h], rdx
│           0x140007a44      4889442440     mov qword [var_40h], rax
│           0x140007a49      c744244875..   mov dword [var_48h], 0x7d657275 ; '***}'
│                                                                      ; [0x7d657275:4]=-1
│           0x140007a51      e8fa9affff     call fcn.140001550
.....
```

断片的に見えていたのは、フラグの文字列をスタックに積む命令の一部だったようです。

元々は `char flag[] = "Alpaca{...}"` のようにローカル変数を宣言するコードだったと思われます。

表示されている文字列をコピーして組み合わせると正しいフラグが得られました。
