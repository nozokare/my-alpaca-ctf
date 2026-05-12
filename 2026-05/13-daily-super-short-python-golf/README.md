# Super Short Python Golf

https://alpacahack.com/daily/challenges/super-short-python-golf

## 問題の概要

Python で、入力した 6 文字以内の ascii 文字列が `eval` される Jail 問題です。

フラグは

```python
ALPACA_FLAG = os.environ.get("FLAG", "Alpaca{dummy}")
```

のようにローカル変数に読み込まれています。

## 解法

[Python の組み込み関数](https://docs.python.org/ja/3/library/functions.html) の一覧をみて、使えそうなものを探してみます。

`eval` された結果が `print` されるわけでもないので、`vars()` などは無意味です。

いろいろ試してみると、`help()` を実行すると対話的なヘルプシステムが起動し、これが使えそうでした。

```
code > help()
Welcome to Python 3.14's help utility! If this is your first time using
Python, you should definitely check out the tutorial at
https://docs.python.org/3.14/tutorial/.

...

To quit this help utility and return to the interpreter,
enter "q", "quit" or "exit".

help>
```

例えば `os` と入力すると、`os` モジュールのドキュメントが表示されます。

```
help> os
Help on module os:

NAME
    os - OS routines for NT or Posix depending on what system we're on.

MODULE REFERENCE
    https://docs.python.org/3.14/library/os#module-os

...

DATA
    ...
    devnull = '/dev/null'
    environ = environ({'PATH': '/usr/local/bin:/usr/local/sbin...SOCAT_PEE...
    environb = environ({b'PATH': b'/usr/local/bin:/usr/local/sb...AT_PEERP...
    extsep = '.'
    ...
```

DATA セクションに `os.*` の内容が表示されていますが、惜しくもフラグは表示されていません。

いろいろ試してみると、どうやら `help` は指定したモジュールを import して docstring などを表示しているようです。

`jail` を指定すると `jail.py` が実行されて DATA セクションに変数が表示され、フラグが見えました。

```
help> jail
code > 1
Help on module jail:

NAME
    jail

DATA
    ALPACA_FLAG = 'Alpaca{REDACTED}'
    code = '1'

FILE
    /app/jail.py
```
