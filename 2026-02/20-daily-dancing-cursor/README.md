# Dancing Cursor

https://alpacahack.com/daily/challenges/dancing-cursor

## 問題の概要

配布されている `print-flag.sh` を実行するとフラグが表示される…はずですが、途中でターミナルに出力された文字列を消しているため、最終的にはフラグが表示されません。

## 解法

`print-flag.sh` の出力を一度 `flag.txt` に保存して内容を確認してみます。

```
Here is the flag:
[?1049h[1B[1;38;5;196mA{...中略...}[K[1AXiqxox{==============================================}
[?1049l... but it has been wiped away.
```

TTY を制御するエスケープシーケンスでカーソルを移動させたり、画面を消去したりしているようです。
せっかくなので 1byte ずつ出力して Dancing Cursor の動きを見てみます。

```python
with open("flag.txt") as f:
    data = f.read().strip()

import time

for c in data:
    print(c, end="", flush=True)
    time.sleep(0.02)
```

カラフルな装飾とともにフラグが表示されました。
出力が消される前まで実行してフラグをコピーすれば提出できます。

### 使用されているエスケープシーケンス

- `\x1b[?1049h` : Alternate Screen Buffer を有効にする
- `\x1b[?1049l` : Alternate Screen Buffer を無効にする
- `\x1b[#A` : カーソルを # 行上に移動する
- `\x1b[#B` : カーソルを # 行下に移動する
- `\x1b[#C` : カーソルを # 列右に移動する
- `\x1b[#D` : カーソルを # 列左に移動する
- `\x1b[#K` : カーソル位置から行末までを消去する
- `\x1b[1;38;5;196m` : 文字色の変更(例)
- `\x1b[m` : 文字装飾のリセット

ANSI エスケープシーケンスの一覧は、次のページにまとめられていて参考になりました。

https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
