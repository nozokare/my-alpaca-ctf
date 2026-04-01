# Message For You

https://alpacahack.com/daily/challenges/message-for-you

## 問題の概要

Flask ベースの Web アプリケーションで、セッションにフラグが保存されて返答されます。

サーバーのコードの主要部分は以下のようになっています。

```python
app = Flask(__name__)
app.secret_key = secrets.token_hex(32)

...

@app.get("/")
def index():
    session["message"] = MESSAGE
    return HTML
```

`MESSAGE` がフラグを含む文字列で、`HTML` は固定のテキストです。

## 解法

`app.secret_key` を予想する余地がないので、セッションデータは暗号化されずにcookieに保存されているんだろうと予想できます。

cookie の値は

```
.eJyrVspNLS5OTE9{ 中略 }.ac1Hdw.VBLSfW7qlgphV1YU5U8x96IEZ4k
```

のようになっており、`.` で区切られた3つのパートから構成されているように見えます。

同じサーバーに複数回アクセスすると、最初のパートは常に同じですが、2,3番目のパートは毎回変わるので、タイムスタンプと署名のようなものだと推測できます。
サーバーを起動しなおすと `app.secret_key` が変わりますが、最初のパートは変わらなかったので、暗号化されていないセッションデータが最初のパートに保存されていると考えられます。

base64 でエンコードされているようなので、デコードしてみます。

```python
session = ".eJyrVspNLS5OTE9....."
data_b64 = session.split(".")[1]
data_b64 += "=" * (-len(data_b64) % 4)
data = base64.urlsafe_b64decode(data_b64)
print(data)
# => b'x\x9c\xabV\xcaM-.NLOU\xb2R\n\xca/N...'
```

あれ、テキストデータになりませんでした。

形式が分からなかったので Flask のソースを確認してみます。
Flask のセッションは `itsdangerous` というライブラリを使用して実装されています。

https://github.com/pallets/itsdangerous/blob/main/src/itsdangerous/url_safe.py

payload の 1 文字目が `"."` で始まる場合、`zlib` で圧縮されたデータが base64 でエンコードされているようです。

```python
import zlib
print(zlib.decompress(data))
# => b'{"message": "Roses are red...."}'
```

無事にフラグを含むメッセージが得られました。

zlib で圧縮されたデータは、先頭の 2 バイトが特徴的なヘッダになっているので見分けられるようになりたいですね。

| バイナリ | bytes     | 意味           |
| -------- | --------- | -------------- |
| `78 9c`  | `'x\x9c'` | デフォルト圧縮 |
| `78 01`  | `'x\x01'` | 圧縮なし       |
| `78 5e`  | `'x^'`    | 低圧縮         |
| `78 da`  | `'x\xda'` | 最高圧縮       |
