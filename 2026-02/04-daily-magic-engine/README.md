# Magic Engine

https://alpacahack.com/daily/challenges/magic-engine

## 問題の概要

Virtual Host が設定されている NGINX サーバーに対して、HTTP リクエストを送信することで、フラグを取得する問題です。

デフォルトは `index.html`、`nip.ip` のドメインでアクセスすると `hello.html`、`admin.alpaca.secret` でアクセスすると `secret.html` が返されます。

フラグは `secret.html` に記載されています。

## 解法

`Host` ヘッダを `admin.alpaca.secret` にしてリクエストを送ると `secret.html` が返されます。

```bash
curl -H "Host: admin.alpaca.secret" http://localhost:3000
```
