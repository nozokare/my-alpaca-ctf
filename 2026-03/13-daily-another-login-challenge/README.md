# Another Login Challenge

https://alpacahack.com/daily/challenges/another-login-challenge

## 問題の概要

簡易的なログイン機能が実装されているExpressアプリケーションで、ログインに成功するとフラグが表示されるという問題です。

認証情報は

```js
let users = {
  admin: {
    password: crypto.randomBytes(32).toString("base64"),
  },
};
```

で管理されており、認証処理の実装は

```js
app.post("/", (req, res) => {
  const { username, password } = req.body;
  const user = users[username];
  if (!user || user.password !== password) {
    return res.send("invalid credentials");
  }

  res.send(FLAG);
});
```

のようになっています。

## 解法

タイミングセーフでないパスワード比較を利用しているのが目につきましたが、インターネット経由で `memcmp` の差を検知するレベルのサイドチャネル攻撃を実現するのは現実的ではありません。

ヒントを見て、JSのオブジェクトの仕様を利用する問題だと気づきました。

`users[username]` が falsy でなく、かつ `user.password` が存在しないような値を `username` に入力すれば、`password` が `undefined` であればログインに成功してしまいます。

例えば、`username` が `"toString"` のとき、`Object.prototype` のプロパティにアクセスしてしまい、

```js
const user = users["toString"]; // Object.prototype.toString
if (!user /* false */ || user.password /* undefined */ !== password) {
  return res.send("invalid credentials");
}
```

のように評価されてしまいます。

## 実行方法

```bash
curl -X POST -d "username=toString" http://localhost:3000/
```

## どう実装すれば安全か

`users.hasOwnProperty(username)` でユーザー名が `users` オブジェクト自身のプロパティであるかどうかをチェックするか、`Map` を利用してユーザー情報を管理するようにすれば、この問題は修正できます。

入力された `password` が `undefined` なのを許容しているのも問題の一部です。
ユーザーから送信されたデータはすべて信頼できないものとして扱い、サーバー側で検証するのがWebアプリケーションのセキュリティの鉄則です。
処理前に `username` と `password` が `string` 型であることや、必要に応じて文字列の長さや使用可能な文字の検証を行いましょう。

パスワード比較のタイミング攻撃については、`crypto.timingSafeEqual` で比較すれば防ぐことができます。

```js
const users = new Map();
users.set("admin", {
  password: crypto.randomBytes(32).toString("base64"),
});

app.post("/", (req, res) => {
  const { username, password } = req.body;
  if (typeof username !== "string" || typeof password !== "string") {
    return res.send("invalid credentials");
  }

  const user = users.get(username);
  if (
    !user ||
    !crypto.timingSafeEqual(Buffer.from(user.password), Buffer.from(password))
  ) {
    return res.send("invalid credentials");
  }

  res.send(FLAG);
});
```

ただ、おそらく問題を単純化する都合でパスワードを平文で保存して直接比較していますが、実際のサービスではパスワードは `bcrypt` などでハッシュ化して保存し、専用の比較関数を利用するべきです。

ログインの試行に段階的なレート制限を設けるのもサイドチャネル攻撃やブルートフォース攻撃を防ぐのに有効です。
実際のサービスでは、

- アカウント単位の失敗回数をカウントする
- 一定回数失敗したら指数的に待ち時間を増やす
- さらに失敗が続く場合はCAPTCHAを要求する
- それでも失敗が続く場合はアカウントをロックし、パスワードのリセットを要求する
- IPアドレス単位の失敗回数もカウントして、同一IPからの攻撃を検知する

のような対策が考えられます。

追加のセキュリティ対策として、多要素認証（MFA）を導入することも有効です。

## 参考

[Authentication - OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
