# Panic

https://alpacahack.com/daily/challenges/panic

## 問題の概要

Fastify という Node.js の Web フレームワークを使用しているサーバーでエラーを発生させるとフラグが得られる問題です。

サーバーのコードの主要部分は以下のようになっています。

```js
fastify()
  // Accept all requests
  .all("/*", (req, reply) => reply.type("text/html; charset=utf-8").send(index))
  // Panic!
  .setErrorHandler((error) => process.env.FLAG)
  // Run the server
  .listen({ port: 3000, host: "0.0.0.0" });
```

`index` は固定の HTML テキストです。

## 解法

ローカルでコードを書き換えて試してみたところ、`400 Bad Request` や `404 Not Found` などのエラーは Fastify のデフォルトのエラーハンドラで処理され、リクエストハンドラ内で発生したエラー(`500 Internal Server Error` になるもの)が `setErrorHandler` で処理されるようです。

いろいろ試してみたところ、次のようなリクエストで `415 Unsupported Media Type` エラーが発生し、フラグを得ることができました。

```
POST / HTTP/1.1
Host: a
Content-Type: a


```

HTTP リクエストの改行コードは CRLF なので、`nc` コマンドで `-C` オプションを付けて送信します。

```bash
$ cat request.txt | nc -C localhost 3000
```
