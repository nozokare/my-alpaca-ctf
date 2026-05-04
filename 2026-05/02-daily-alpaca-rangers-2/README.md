# Alpaca Rangers 2

https://alpacahack.com/daily/challenges/alpaca-rangers-2

## 問題の概要

`/member?img={path}` で指定した画像が `/app/images/{path}` から読み込まれる Web アプリでフラグを読み込む問題です。
ただし、ディレクトリトラバーサルを防ぐために `"../"` は `str.replace` で置換されています。

```python
path = path.replace("../", "") # Prevents directory traversal
path = "./images/" + path
try:
    img = open(path, "rb").read()
except:
    img = notfound
```

フラグは `/flag.txt` に配置されています。

## 解法

`str.replace` はすべての出現ヵ所で置換を行いますが、置換後の文字列に対しては再度置換を行いません。

したがって <code>"..<span style="color: #f88">../</span>/"</code> のように `"../"` の間に `"../"` を挟むことで、置換後の文字列に `"../"` が残るようにできます。

## 解答に使用したコード

```bash
curl http://localhost:1337/member?img=....//....//flag.txt
```
