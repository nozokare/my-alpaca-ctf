# permission denied 3

https://alpacahack.com/daily/challenges/permission-denied-3

## 問題の概要

[permission denied](https://alpacahack.com/daily/challenges/permission-denied)、[permission denied 2](https://alpacahack.com/daily/challenges/permission-denied-2)に続く 3 問目です。
今回は `chal.sh` も `flag.txt` も削除されてしまいます。

```bash
echo Alpaca{REDACTED} |
install -m 400 /dev/stdin flag.txt
rm *
sh
```

## 解法を考える

最初に permission denied のような Race Condition が思い当たります。

同時に 2 つの接続を行い、`cat flag.txt` を実行させます。起動した `bash chal.sh` のプロセスを P1, P2 とすると

- P2 が `chal.sh` を読み込んでスタート
- P1 が `rm *` を実行
- P2 が `flag.txt` を作成
- P1 が `sh` で `cat flag.txt` を実行
- P2 が `rm *` を実行

のような順番で実行されればフラグを読み込むことができます。

しかし、`sh` の起動 + `cat flag.txt` の実行は重く、P2 が `flag.txt` を作成してから `rm *` を実行するまでの間に実行される可能性はかなり低そうです。

試行チャンスはインスタンスを起動した後の 1 回だけなので、もうすこし確実に成功させる方法を考える必要があります。

### 削除された `chal.sh` の内容を読む

`bash chal.sh` プロセスは `chal.sh` の内容を読み込んでいるはずです。今回は root 権限でコマンドを実行できるため、`bash chal.sh` プロセスが開いている FD をのぞくことができそうです。

```
# head /proc/*/cmdline | tr '\0' '\n'
...
==> /proc/8/cmdline <==
bash
chal.sh
...

# ls -la /proc/8/fd
total 0
dr-x------ 2 root root  4 May  7 05:38 .
dr-xr-xr-x 9 root root  0 May  7 05:38 ..
lrwx------ 1 root root 64 May  7 05:40 0 -> /dev/pts/0
lrwx------ 1 root root 64 May  7 05:40 1 -> /dev/pts/0
lrwx------ 1 root root 64 May  7 05:40 2 -> /dev/pts/0
lr-x------ 1 root root 64 May  7 05:40 255 -> '/app/chal.sh (deleted)'
```

FD 255 で開かれた `chal.sh` への参照が残っています。これを読み取ることで、`chal.sh` の内容を知ることができます。

## 解答に使用した入力

コンテナ起動後に最初に接続したときの `bash chal.sh` の PID と FD 番号には再現性があるようで、決め打ちで成功しました。

```bash
cat /proc/8/fd/255
```

## なぜ削除したファイルを読むことができるのか

Linux のファイルは実体を表す inode と、inode への参照であるディレクトリエントリから構成されます。`rm` はディレクトリエントリを削除するだけで、inode は全ての参照がなくなるまで削除されません。

今回は `bash chal.sh` が open した FD が inode を参照しているため、`rm` で削除された後も inode は残ったまま有効で読み出すことができました。
