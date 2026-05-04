# Alpaca++

https://alpacahack.com/daily/challenges/alpaca-plus-plus

## 問題の概要

> Unicodeコードポイント順において、「🦙」の次に位置する絵文字をフラグ形式で答えてください。

## 解法

### JavaScript

JavaScript の文字列は UTF-16 コード単位の列で表現されています。
"🦙" はサロゲートペアで表現されるため、1文字ですが長さは2になります。

```javascript
"🦙".length; // => 2
"🦙".charCodeAt(0).toString(16); // => 'd83e'
"🦙".charCodeAt(1).toString(16); // => 'dd99'
("\ud83e\udd99"); // => '🦙'
("\ud83e\udd9a"); // => '🦚'
```

`String.prototype.codePointAt()`, `String.fromCodePoint()` を使用すると、サロゲートペアを正しく処理できます。

```javascript
"🦙".codePointAt(0).toString(16); // => '1f999'
("\u{1f999}"); // => '🦙'
("\u{1f99a}"); // => '🦚'
String.fromCodePoint("🦙".codePointAt(0) + 1); // => '🦚'
```

### Python

Python の文字列は Unicode コードポイントの列で表現されているため、1文字は1コードポイントに対応します。

```python
len("🦙") # => 1
hex(ord("🦙")) # => '0x1f999'
chr(ord("🦙") + 1) # => '🦚'
```
