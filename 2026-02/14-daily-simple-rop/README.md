# simple ROP

https://alpacahack.com/daily/challenges/simple-rop

## 問題の概要

ROP で `win` 関数に特定の引数を渡して呼び出せば shell に execve される PWN 問題です。

プログラム開始時に `win` のアドレスが知らされ、ローカル変数 `char buf[64]` に `gets(buf)` で入力を書き込みます。

引数を渡すために次のようなガジェットが用意されています。

```c
__asm__(
    "pop %rdi\nret\n"
    "pop %rsi\nret\n"
    "pop %rdx\nret\n"
);
```

### バイナリ情報

```
Arch:       amd64-64-little
RELRO:      Full RELRO
Stack:      No canary found
NX:         NX enabled
PIE:        PIE enabled
SHSTK:      Enabled
IBT:        Enabled
Stripped:   No
```

## 解法

`gets(buf)` で入力の長さに制限がないため、バッファオーバーランでスタックを上書きできます。

Stack Canary がないため、main 関数のリターンアドレスを上書きする ROP が可能です。

`objdump -d chal` でアセンブリを確認すると、ガジェットと `win` 関数が次のように配置されていることがわかります。

```s
...
    11e9:	5f             	pop    %rdi
    11ea:	c3             	ret
    11eb:	5e             	pop    %rsi
    11ec:	c3             	ret
    11ed:	5a             	pop    %rdx
    11ee:	c3             	ret

00000000000011ef <win>:
    11ef:	f3 0f 1e fa    	endbr64
    11f3:	55             	push   %rbp
...
```

pop はスタックから取り出した値をレジスタにセットし、ret はスタックから取り出したアドレスにジャンプするため、スタックを次のように構築すれば `rdi`(第1引数)、`rsi`(第2引数)、`rdx`(第3引数) に値をセットして `win` 関数を呼び出せます。

| addr | 旧内容                  | 内容                 |
| ---- | ----------------------- | -------------------- |
| rsp→ | buf[64]                 | (任意)               |
| rbp→ | 旧 rbp                  | (任意)               |
|      | main のリターンアドレス | `pop rdi` のアドレス |
|      | ...                     | rdi に渡す値         |
|      |                         | `pop rsi` のアドレス |
|      |                         | rsi に渡す値         |
|      |                         | `pop rdx` のアドレス |
|      |                         | rdx に渡す値         |
|      |                         | `win` のアドレス     |

### 解答に使用したコード

- [solve.py](solve.py)
