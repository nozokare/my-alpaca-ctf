# unheard

https://alpacahack.com/daily/challenges/unheard

## 問題の概要

Python プログラムで、入力した `code` が `exec` されますが、`sys.addaudithook` で特定の[監査イベント](https://docs.python.org/ja/3/library/audit_events.html)以外はブロックされます。

```python
import sys
import os

# Hint1: sys.addaudithook() registers a callback that Python invokes on security-sensitive operations (file opens, imports, exec, etc.).
# ヒント1: sys.addaudithook()は、セキュリティ上重要な操作（ファイルのオープン、インポート、execなど）の際にPythonが呼び出すコールバックを登録します。

# Hint2: Audit hooks are PERMANENT, once installed they cannot be removed or bypassed from Python code.  ...or can they?
# ヒント2: 監査フックは永続的であり、一度設定されるとPythonコードから削除もバイパスもできません。…本当にそうでしょうか？

_flag_fd = os.open("flag.txt", os.O_RDONLY)

del os

code = input("> ")

_ALLOWED = frozenset({"compile", "exec"})


def _audit_hook(event, _args, _allowed=_ALLOWED):
    if event not in _allowed:
        raise PermissionError(f"blocked: {event}")


sys.addaudithook(_audit_hook)

del _flag_fd, _audit_hook, _ALLOWED

try:
    exec(compile(code, "<jail>", "exec"), {"__builtins__": __builtins__, "sys": sys})
except Exception as e:
    print(f"error: {e}")
```

## 解法

`open` や `os.system` などの操作は監査フックでブロックされるため、

```python
print(open("flag.txt").read())
print(__import__("os").system("cat flag.txt"))
```

のようなコードは実行できません。

`import` もブロックされそうですが、一度 import でロードされたモジュールは `sys.modules` に残り、2回目以降はこれを参照するだけでファイルアクセス等を伴わないため、ブロックされないようです。

また、`_flag_fd` は `del` されているため参照できませんが、ファイルディスクリプタを close していないため、FD 番号は有効で残っています。

したがって、この FD 番号を `os.read` で読み取ればフラグを得ることができます。

## 解答に使用した入力

FD 0, 1, 2 はそれぞれ stdin, stdout, stderr で使用されており、`_flag_fd` はおそらく 3 になります。

```
import os; print(os.read(3, 100))
```

`os` モジュールへのアクセスは `__import__("os")` や `sys.modules.get("os")` などでも可能です。
