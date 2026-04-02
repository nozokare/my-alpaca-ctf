# silence

https://alpacahack.com/daily/challenges/silence

## 問題の概要

Python で、入力した文字が `cat flag.txt > ` に続く出力先として指定されて `run` されます。
ただし、標準入力、標準出力、標準エラーはすべて `DEVNULL` にリダイレクトされます。

```python
from subprocess import run, DEVNULL

run('cat flag.txt > ' + input('cat flag.txt > ')[:10], shell=True, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
```

## 解法

`/dev/stdout` を指定すると `run` で起動した shell プロセスの標準出力にフラグが出力されますが、これは `DEVNULL` にリダイレクトされているため、フラグは表示されません。

サーバーの TCP ポートに接続すると、`socat` によって Python プロセスが起動されます。

```dockerfile
CMD ["socat", "TCP-L:1337,fork,reuseaddr", "EXEC:'python jail.py',stderr,pty,ctty,setsid,echo=0"]
```

この Python プロセスの標準出力が `socat` によって TCP ソケットに転送され、クライアントに返されています。

今回は `pty` オプションが指定されているため、仮想端末デバイス `/dev/pts/0` が作成され、Python プロセスの標準出力はこのデバイスに出力されます。

したがって、`/dev/pts/0` にフラグを出力するように指定すればクライアントにフラグが返されます。

```bash
nc localhost 1337
cat flag.txt > /dev/pts/0
Alpaca{*** REDACTED ***}
```
