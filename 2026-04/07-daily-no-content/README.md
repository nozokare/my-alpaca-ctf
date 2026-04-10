# No Content

https://alpacahack.com/daily/challenges/no-content

## 問題の概要

Python の `http.server` ベースのサーバーで、`/` にアクセスすると、ステータスコードが `204 No Content` で `Content-Length: 0` が設定されているが body にフラグが含まれるレスポンスが返されます。

## 解法

ブラウザや curl 等の HTTP クライアントは、ステータスコードが `204 No Content` のレスポンスや `Content-Length: 0` のレスポンスを受け取ると body を無視してしまいます。

nc コマンド等で直接 TCP 接続して HTTP リクエストを送ると、レスポンスの body を確認できます。

```bash
printf "GET / HTTP/1.1\r\n\r\n" | nc localhost 3000
```

あるいは、curl コマンドで `-vvvv` オプションをつけると送受信したデータの内容を全て確認することができます。

```bash
curl -vvvv http://localhost:3000/
```
