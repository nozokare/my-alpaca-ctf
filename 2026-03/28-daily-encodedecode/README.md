# EncodeDecode

https://alpacahack.com/daily/challenges/encodedecode

## 問題の概要

入力した `text` を指定した `encoding` で encode → decode した結果が `text` と異なるようにするとフラグが得られる問題です。

`text` は ASCII 文字 (0x00-0x7F) である必要があります。

## 解法

入力が ASCII 文字に限られているため、通常の文字セットであれば encode → decode しても同じ文字列になりそうです。

特殊なエンコーディングがないか [ドキュメント](https://docs.python.org/ja/3/library/codecs.html#python-specific-encodings) を確認してみると、`unicode_escape`、`raw_unicode_escape` というかなりあやしいエンコーディングが見つかりました。

いろいろ試したところ、次の入力でフラグが得られました。

```
text> \u1111
encoding> raw_unicode_escape
```

`unicode_escape` はエンコーディングは Python の文字リテラルのようにバックスラッシュエスケープを処理するエンコーディングです。

decode 時にのようなエスケープが解釈されます：

- `\n`, `\t`, `\\` などの一般的なエスケープシーケンス
- `\uXXXX`, `\UXXXXXXXX` 形式の Unicode コードポイントエスケープ
- `\xXX` 形式の 16 進数エスケープ
- `\OOO` 形式の 8 進数エスケープ

encode 時は制御文字や `\` をバックスラッシュエスケープし、ASCII 以外の文字を `\uXXXX` 形式でエスケープします。

```python
a = 'あ\n\\' # (あ, \n, \)
a = a.encode("unicode_escape")
# => b'\\u3042\\n\\\\'  (\, u , 3, 0, 4, 2, \, n, \, \)
a = a.decode("unicode_escape")
# => 'あ\n\\' (あ, \n, \)
```

`raw_unicode_escape` は `unicode_escape` とほぼ同様ですが、`\n`, `\t`, `\\` などの一般的なエスケープシーケンスは解釈せず、文字列をそのまま出力します。

```python
a = 'あ\n\\' # (あ, \n, \)
a = a.encode("raw_unicode_escape")
# => b'\\u3042\n\\'  (\, u , 3, 0, 4, 2, \n, \)
a = a.decode("raw_unicode_escape")
# => 'あ\n\\' (あ, \n, \)
```

解答に使用した入力では、encode 時に `\` がエスケープされずに残り、decode 時に Unicode コードポイントエスケープとして解釈されるため、元の文字列と異なる結果になります。

```python
a = '\\u1111' # (\, u , 1, 1, 1, 1)
a = a.encode("raw_unicode_escape")
# => b'\\u1111'  (\, u , 1, 1, 1, 1)
a = a.decode("raw_unicode_escape")
# => 'ᄑ' (U+1111)
```

## 参考

- https://docs.python.org/ja/3/howto/unicode.html
- https://docs.python.org/ja/3/library/codecs.html#python-specific-encodings
