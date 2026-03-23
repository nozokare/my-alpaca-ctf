# Alpacker

https://alpacahack.com/daily/challenges/alpacker

## 問題の概要

入力した Flag が正しいかどうかを判定する ELF 形式のバイナリが与えられています。
リバースエンジニアリングを行い、正しい Flag を見つける問題です。

## 方針

こういった問題を解くのが初めてで、どこから手を付けていいのか分からなかったため、ChatGPT に相談しながら進めました。

objdump, gdb, pwndbg, Ghidra, radare2 など、いろいろなツールを試してみましたが、個人的には CLI で操作できる [radare2](https://github.com/radareorg/radare2) が扱いやすかったです。

## バイナリ情報

```bash
$ file chal
chal: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=..., for GNU/Linux 3.2.0, stripped

$ checksec chal
[*] '....../chal'
    Arch:       amd64-64-little
    RELRO:      Full RELRO
    Stack:      Canary found
    NX:         NX enabled
    PIE:        PIE enabled
    SHSTK:      Enabled
    IBT:        Enabled

$ nm chal
nm: chal: no symbols

$ strings chal
PTE1
u+UH
flag:
wrong...
correct!
:*3$"
(フラグの候補と思われる文字列は見当たらない)
```

シンボルはすべて削除されており、デバッグ情報も含まれていないため、アセンブリコードを読んで解析する必要があります。

## アセンブリの解析

radare2 + r2ghidra で main 関数をデコンパイルすると [decompiled.c](decompiled.c) のようなコードが得られました。

変数名を変えて整理すると次のようなコードになります。

```c
int main(int argc, char **argv, char **envp) {
    int is_correct;
    char *pos;
    char *code;
    int i;
    char buf[0x80];

    printf("flag: ");

    if (fgets(buf, 0x80, stdin) == 0) {
        return 1;
    }
    pos = strchr(buf, 10);
    if (pos != NULL) {
        *pos = 0;
    }
    if (strlen(buf) != 0x24) {
        puts("wrong...");
        return 0;
    }

    code = mmap(NULL,0x11b,7,0x22,-1,0);
    if (code == 0xffffffffffffffff) {
        return 1;
    }
    memcpy(code, 0x4020, 0x11b);
    for (i = 0; i < 0x11b; i = i + 1) {
        code[i] = code[i] * 's';
    }
    is_correct = ((int (*)())code)(buf);
    if (is_correct == 0) {
        puts("wrong...");
    } else {
        puts("correct!");
    }
    return 0;
}
```

内容を整理すると、次のような処理を行っていることが分かります。

- `mmap` で実行可能なメモリ領域を作成
- アドレス `0x4020` からデータを読み込み(長さ `0x11b`)
- データを `b => b * 's'` のように変換し、実行可能なコードを作成
- コードとして実行し、入力された Flag が正しいかどうかを判定

## データの解析

Pythonで `pwntools` を使ってアドレス `0x4020` のバイト列を取得し、変換して逆アセンブルしてみます。

```python
from pwn import *
elf = ELF("chal")
prog = elf.section(".data")[0x20 : 0x20 + 0x11b]
prog_decoded = bytes([(b * ord('s')) % 256 for b in prog])
print(disasm(prog_decoded))
```

```s
   0:   31 c0                   xor    eax, eax
   2:   80 3f 41                cmp    BYTE PTR [edi], 0x41
   5:   0f 85 0f 01 00 00       jne    0x11a
   b:   80 7f 23 7d             cmp    BYTE PTR [edi+0x23], 0x7d
   f:   0f 85 05 01 00 00       jne    0x11a
  15:   80 7f 01 6c             cmp    BYTE PTR [edi+0x1], 0x6c
  19:   0f 85 fb 00 00 00       jne    0x11a
  ...
 10f:   80 7f 16 63             cmp    BYTE PTR [edi+0x16], 0x63
 113:   75 05                   jne    0x11a
 115:   b8 01 00 00 00          mov    eax, 0x1
 11a:   c3                      ret
```

渡したバッファの内容をスクランブルされた順番で1バイトずつ比較していることが分かります。

比較されている値を順番に並べるとフラグが得られます。

```python
prog_hex = prog_decoded.hex(" ")

buf = [0] * 0x24
buf[0] = int(re.search(r"80 3f (..)", prog_hex).group(1), 16)
for addr, val in re.findall(r"80 7f (..) (..)", prog_hex):
    buf[int(addr, 16)] = int(val, 16)
print(bytes(buf))
```

完全なコードは [analyze.ipynb](analyze.ipynb) を参照してください。
