# What's Next

https://alpacahack.com/daily/challenges/whats-next

## 問題の概要

Next.js サーバーのソースコードが与えられています。

```
web/src
└── pages
    ├── _app.js
    ├── _document.js
    ├── index.js
    └── secret.js
```

`secret.js` に対応するルートにアクセスするとフラグが表示されます。

ただし、`Dockerfile` で `secret.js` がランダムな名前に変更されています。

```bash
RUN mv src/pages/secret.js src/pages/secret-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32).js
```

## 解法

ページにアクセスし、DevTools でソースを確認すると `_next/static/{build-id}/_buildManifest.js` というファイルを読み込んでいることがわかります。

このファイルに Next.js アプリのページ一覧やページごとに読み込むべき JS/CSS チャンクの情報が含まれています。

```js:_buildManifest.js
self.__BUILD_MANIFEST = {
  "/": [
    "static/chunks/82e29a3e3a5232ab.js"
  ],
  ....
  "/secret-5Q94........................": [
    "static/chunks/dfe742b27c8089ba.js"
  ],
  ....
  "sortedPages": [
    "/",
    "/_app",
    "/_error",
    "/secret-5Q94........................"
  ]
};self.__BUILD_MANIFEST_CB && self.__BUILD_MANIFEST_CB()
```

`/secret-5Q94....` にアクセスするとフラグが表示されます。
