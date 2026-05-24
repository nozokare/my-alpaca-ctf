# Python:Impossible

https://alpacahack.com/daily/challenges/python-impossible

## 問題の概要

サーバーに接続すると次のようなものを入力するように求められます。

環境変数: `NAME=VALUE` 形式で 1 つ入力
引数: 任意の文字列を 1 つ入力

その後、入力した環境変数と引数で次の `chall.py` が実行されます。

```python
#!/usr/bin/env python3
import os
import sys


n = int(sys.argv[1])
assert n > 0
assert n < 0

print(os.getenv("FLAG", "Alpaca{dummy}"))
```

## 解法

`n` は整数になるので、`assert n > 0` と `assert n < 0` を同時に満たすことは不可能です。

したがって Python の挙動を変える環境変数がポイントになりそうです。

[Python の環境変数](https://docs.python.org/ja/3.14/using/cmdline.html#environment-variables) を調べると、`PYTHONOPTIMIZE` という環境変数が見つかりました。

`PYTHONOPTIMIZE` を 1 以上の値に設定するとデバッグ機能が無効化され、`assert` 文が無視されるようになります。

## 解答に使用した入力

```
env> PYTHONOPTIMIZE=1
arg> 1
Alpaca{REDACTED}
```
