# nc magic

https://alpacahack.com/daily/challenges/nc-magic

## 問題の概要

表示された secret をそのまま返すとフラグが得られる問題です。

ただし、入力が `sys.stdin.buffer.readline()` で読み取られますが、改行が strip されないため改行を含めずに readline に入力の終端を知らせる必要があります。

## 解法

改行を含めずに readline に入力の終端を知らせるためには、EOF を送る必要があります。

ローカルのターミナルでは Ctrl+D を押すことで EOF を送ることができます。

```bash
$ python server.py
Just send back aa8bbb82d4b53a426c06684166a00a33 ... but can you?
aa8bbb82d4b53a426c06684166a00a33(Ctrl+D)(Ctrl+D)Alpaca{REDACTED}
```

サーバーでは `socat` で TCP ソケットとサーバープログラムの標準入出力を接続しています。

クライアントが TCP の FIN を送って half-close すると、標準入力が EOF になって `readline()` が終了し、サーバーがフラグを返すことができます。

`nc` コマンドでは `-N` オプションをつけると、`EOF` を受け取ると接続を half-close することができます。

```bash
$ nc -N localhost 1337
Just send back 949abfb3542400abbecbccb1acf871db ... but can you?
949abfb3542400abbecbccb1acf871db(Ctrl+D)(Ctrl+D)Alpaca{REDACTED}
```

Python の `socket` を使うなら `shutdown(socket.SHUT_WR)` を呼び出すと、クライアントからサーバーへの接続を half-close できます。

```python
import socket

conn = socket.create_connection((host, int(port)))
data = conn.recv(1024).split(b" ")[3]
conn.send(data)
conn.shutdown(socket.SHUT_WR)

print(conn.recv(1024).decode())
```
