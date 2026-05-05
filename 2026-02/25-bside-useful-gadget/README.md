# useful-gadget

https://alpacahack.com/daily-bside/challenges/useful-gadget

## 問題の概要

No PIE, No Canary なバイナリで、ROPチェーンを組んで shell を取得する問題です。

```c
__asm__("pop %rax\nret\n");

int main(void) {
    char buf[0x20];
    puts("what's your name");
    fgets(buf, 0x48, stdin);
    return 0;
}
```

フラグは `./flag-{hash}.txt` に保存されています。

## 解法

`fgets` が `buf` のサイズを超えて読み込んでおり、ROP が可能です。

`chal` バイナリ内のアドレスは固定ですが、フラグを読み出すためには `chal` バイナリ内の命令列だけでは不十分です。

そこで、最終的に libc の one gadget を呼び出すことを目指します。そのためには libc のアドレスをリークさせる必要があります。

### libc のアドレスリーク

`main` 関数の `puts` の呼び出し部分は以下のようになっています。

```s
0x0000000000401184 <+12>:    lea    rax,[rip+0xe79]  # "what's your name"
0x000000000040118b <+19>:    mov    rdi,rax
0x000000000040118e <+22>:    call   0x401060 <puts@plt>
```

`pop rax; ret` gadget で `puts` の GOT を `rax` に読み込んで `<main+19>` にジャンプさせると、`puts` のアドレスがリークできます。

### one gadget

[one_gadget](https://github.com/david942j/one_gadget) を使って、問題の Docker Image 内の libc.so.6 から one gadget を探します。

次の one gadget が constraints を満たしやすそうでした。

```
0xef52b execve("/bin/sh", rbp-0x50, [rbp-0x78])
constraints:
  address rbp-0x50 is writable
  rax == NULL || {"/bin/sh", rax, NULL} is a valid argv
  [[rbp-0x78]] == NULL || [rbp-0x78] == NULL || [rbp-0x78] is a valid envp
```

## 解答に使用したコード

以上を踏まえて、1回目で libc のアドレスをリークして、2回目で one gadget を呼び出す ROP チェーンを組みます。

- [solve.py](solve.py)

main 関数の `ret` 前に `leave` があるため、saved rbp が書き換え可能なアドレスを指すようにする必要があります。
今回は `chal` の BSS セクションの適当なアドレスを saved rbp に指定しました。
