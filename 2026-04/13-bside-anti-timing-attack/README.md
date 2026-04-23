# Anti Timing Attack

https://alpacahack.com/daily-bside/challenges/anti-timing-attack

## 問題の概要

### main 関数

サーバーは Python の `socket` を使用してクライアントからの接続を待ち受け、接続があると `multiprocessing.Process` を使用して新しいプロセスで `handle` 関数を呼び出します。

```python
def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen(BACKLOG)
        print(f"listening on {HOST}:{PORT}", flush=True)
        while True:
            conn, _ = s.accept()
            mp.Process(target=handle, args=(conn,)).start()
            conn.close()
```

`conn.close()` はソケットの FD の参照カウントを減らすだけで、`handle` 関数を呼び出したプロセスで `conn` を閉じるまで FD は実際には閉じられません。

新しいプロセスは完全にメモリ空間が独立しており、複数のコネクションの通信の内容が他のコネクションの処理に影響を与える余地がなく、Race Condition による攻撃はできなさそうです。

### handle 関数

`handle` 関数は、見通しのために例外処理を省略すると以下のようになっています。

```python
def handle(conn):
    end = time.monotonic() + BUDGET
    ok = False
    conn.sendall(b"FLAG: ")
    if wait_line(conn, end):
        ok = True
        for c in FLAG:
            x = conn.recv(1)
            if not x or x[0] != c:
                ok = False
                break
        ok = ok and conn.recv(1) == b"\n"
    while time.monotonic() < end:
        time.sleep(0.001)
    if ok:
        conn.sendall(b"correct!\n")
    conn.close()
```

`wait_line` 関数は、時刻 `end` までに `conn` に 1 行分のデータが到着すれば True、来なければ False を返す関数です。0.01 秒ごとに `conn` にデータが来ていないかを確認し、バッファを消費せずにデータを先読みし、`"\n"` が含まれているかを確認しています。

1行分のデータが来たら 1 バイトずつバッファから取り出して FLAG と比較し、FLAG と一致しないバイトがあれば `ok` を False にしてループを抜けます。

その後、比較時間によるタイミング攻撃を防ぐために時刻 `end` まで待機して応答時間を一定にし、最後に `ok` が True なら "correct!" と返します。

## 解法

ローカルで試したところ、途中まで正しいフラグ `Alpaca{` を送ったときは `EOFError` が、途中で間違っているフラグ `Alpaca*` を送ったときは `ConnectionResetError` が発生していました。

```python
from pwn import remote
host, port = "localhost", 9999

with remote(host, port) as conn:
    conn.sendlineafter(b"FLAG: ", b"Alpaca{")
    conn.recv(1024)
    # => EOFError

with remote(host, port) as conn:
    conn.sendlineafter(b"FLAG: ", b"Alpaca*")
    conn.recv(1024)
    # => ConnectionResetError
```

前者の場合はバッファの `Alpaca{\n` の `\n` まで読み取られますが、後者の場合は `Alpaca*\n` の `*` までしか読み取られずにループを抜けます。

Linuxでは `conn.close()` 時にバッファが空であれば FIN パケットで接続を終了し、バッファにデータが残っていれば RST パケットで接続をリセットする実装になっており、この差を利用して FLAG を 1 バイトずつ特定できます。

### 環境差で沼る

さて、ソルバーを書いて実行してみると、ローカルの作業環境で直接 `python chall.py` で起動したサーバーではうまく FLAG を特定できましたが、Docker で起動したサーバーや本番の問題サーバーでは全て `EOFError` になってしまい、FLAG を特定できませんでした。

問題の説明で環境の実装差異で挙動が違うことがある、と注意されていたので「環境によっては `ok = ok and conn.recv(1) == b"\n"` の部分が short circuit されないのか？？」などとかなり迷走してしまいました。

最終的に Windows ホストの NIC の通信を Wireshark でキャプチャしたパケットと WSL2 上の DevContainer 内で tcpdump でキャプチャしたパケットを比較して、

```
リモートサーバー
  ↓
  ...
  ↓
Windows ホスト NIC
  ↓ (NAT/vSwitch)
WSL2 VM 仮想 NIC
  ↓
docker0
  ↓ (NAT: iptables)
DevContainer veth
```

の経路で、Windows ホストの NIC までは RST パケットで接続がリセットされているのに対し、DevContainer 内では FIN パケットで接続が終了していることがわかりました。

どうやら Docker の NAT が RST での接続リセットを FIN での接続終了に変換してしまっているようです。

サーバー側の実装差だけでなく、クライアント側の環境差も問題で、プロキシを経由するような企業・学校のネットワーク環境からだと原理的に解けないことがある気がしますが、自分の環境では Windows ホストまでは RST が届いていたため、FLAG を特定することができました。

## 解答に使用したコード

実行環境で `pwntools` のインストールを省くために生の `socket` で処理しています。

- [solve.py](solve.py)

## 感想

なんとなくすぐ解けそうな気がして後回しにしていたら期限ギリギリになってしまい、環境差で沼って無事に間に合いませんでした。

宿題は時間があるうちに早めに終わらせようね…
