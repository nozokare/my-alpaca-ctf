# Catrunner

https://alpacahack.com/daily/challenges/catrunner

## 問題の概要

ファイル名を入力すると `path.join('/app', filename)` で結合されたパスのファイルが存在すれば `cat` で表示されます。
ただし、`filename` に `..` を含めるとエラーになるため、単純なディレクトリトラバーサルは封じられています。

フラグは `/flag.txt` に配置されています。

## 解法

[os.path.join のドキュメント](https://docs.python.org/ja/3.14/library/os.path.html#os.path.join) を見てみると、絶対パスを指定するとそれ以前に指定された引数は無視されるようです。

> ```python
> >>> os.path.join('/home/foo', 'bar')
> '/home/foo/bar'
> >>> os.path.join('/home/foo', '/home/bar')
> '/home/bar'
> ```

したがって `/flag.txt` を指定すればフラグを読むことができました。
