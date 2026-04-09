# Plz Login

https://alpacahack.com/daily/challenges/plz-login

## 問題の概要

デバッグモードが有効な Flask アプリケーションで、ログインに成功するとフラグが表示される問題です。

認証部分は以下のようになっています。

```python
@app.post("/login")
def login():
    username = request.form.get("username", "")
    password = request.form.get("password", "")

    if username[0] not in "aA" or username[1:] != "dmin" or password != "**REDACTED**":
        return render_template("login.html", error="You are not Admin"), 401

    return render_template("flag.html", flag=FLAG)
```

パスワードはハードコードされており、実際はランダムな文字列になっています。

## 解法

デバッグモードが有効なので、エラーを引き起こすと該当部分のコードが表示されます。

HTML フォームの長さ制限を無視して `username` に長さ 0 の文字列を渡せば `username[0]` で index out of range エラーが発生し、ハードコードされたパスワードが表示されます。

## 実行方法

DevTools でフォームの input 要素を削除して送信しすればエラー画面でパスワードを確認できます。
得られたパスワードとユーザー名 "Admin" でログインすればフラグが表示されます。
