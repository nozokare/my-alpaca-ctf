# Pyrunner

https://alpacahack.com/daily-bside/challenges/pyrunner

## 問題の概要

実在するファイル名を入力するとそのファイルが Python で実行されます。

- バリデーション: `os.path.isfile(path)`
- 実行: `os.system(f"python {path}")`

フラグはランダムなファイル名に変えられて `/flag-{md5sum}.txt` に配置されています。

## 方針を考える

方針として、次のようなものを思いつきました。

1. `os.path.isfile` では存在するファイル名として認識されるが `os.system` ではコマンドとして解釈される文字列を入力し、コマンドインジェクションを狙う
2. 対話的な機能を持っている Python プログラムが記述されているファイルを指定して実行する
3. `/dev/stdin` のような特殊なファイルを指定して、Python コードを標準入力から読み込んで実行する

3 は `isfile` が一般ファイルでないと False を返すため不可能でした。
1 はスペースや特殊文字を含む既存のファイルが存在しないといけないため難しそうです。

2 について、ローカルのコンテナで `*.py` ファイルを列挙し、全てのファイルを実行してみました。

```bash
for file in $(find / -name "*.py"); do echo $file; python $file 2> /dev/null; done
```

結果、次のファイルが使えそうでした。

- `/usr/local/lib/python3.14/sqlite3/__main__.py`: SQLite3 の対話的なシェルが起動する
- `/usr/local/lib/python3.14/code.py`: Python REPL が起動する

REPL を起動すれば自由に Python コードを実行できるため、フラグを読み取ることができます。

## 解答に使用した入力

```
/usr/local/lib/python3.14/code.py
import os
os.system("cat /flag*.txt")
```

`cat input.txt | nc localhost 1337` のようにするとタイミングが合わずにうまくいかなかったので、コピペで入力しました。
