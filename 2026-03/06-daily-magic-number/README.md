# magic number

https://alpacahack.com/daily/challenges/magic-number

## 問題の概要

Python で20文字以内の入力を与えると、次の`code` が `exec` されます。

```python
code = """
magic = /*code*/
if magic == 2508766360454420426020902195377847924746:
    print("/*flag*/")
else:
    print("bye")
"""
```

実行前に `/*code*/` の部分が入力に置き換えられ、`/*flag*/` の部分はフラグに置き換えられます。

`code` から参照できるのは `print` のみになっています。

```python
exec(compiled, {"__builtins__": {"print": print}}, {})
```

## 解法

`2508766360454420426020902195377847924746` を 20 文字以内で表現できればフラグを得ることができますが、なかなか難しそうです。

`print(/*flag*/)` と入力すると `/*code*/` の部分が `print(/*flag*/)` に置き換えられ、`/*flag*/` の部分がフラグに置き換えられるため、フラグが出力されます。
