# git gc

https://alpacahack.com/daily/challenges/git-gc

## 問題の概要

git で次の作業を行ったディレクトリ(.git を含む)のデータが与えられています。

- リポジトリを初期化
- 空の initial commit を作成
- flag.txt をコミット
- initial commit に hard reset
- `git gc` でクリーンアップ

## 解法

reflog を確認すると、フラグを含むコミットが残っていることがわかります。

```bash
$ git reflog
c0bf20c (HEAD -> main) HEAD@{0}: reset: moving to HEAD~1
75a6ad9 HEAD@{1}: commit: add flag
c0bf20c (HEAD -> main) HEAD@{2}: commit (initial): initial commit
```

コミットの内容を確認すればフラグが得られます。

```bash
$ git show HEAD@{1}
commit 75a6ad9f0abe942df11f90b58f175d553c23c101
Author: AlpacaHack <alpacahack@alpacahack.internal>
Date:   Sat Jan 10 01:45:04 2026 +0900

    add flag

diff --git a/flag.txt b/flag.txt
new file mode 100644
index 0000000..4c820f2
--- /dev/null
+++ b/flag.txt
@@ -0,0 +1 @@
+Alpaca{************************}
```

## git gc について

`git gc --prune=<date>` とすると指定した日時より古い到達不能なオブジェクトが削除されます。

date はデフォルトでは 2 週間前に設定されているため、今回の問題では `git gc` を実行してもフラグを含むコミットが残っていました。

今回の問題のフラグに書かれているように `git gc --prune=now` を指定すれば直前の到達不能オブジェクトも削除されます。

```bash
$ ./generate.sh
...
$ cd chall
$ git gc --prune=now
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Writing objects: 100% (5/5), done.
Total 5 (delta 1), reused 5 (delta 1), pack-reused 0 (from 0)

$ git reflog
4ab7f18 (HEAD -> master) HEAD@{0}: reset: moving to HEAD~1
0f622f8 HEAD@{1}: commit: add flag
4ab7f18 (HEAD -> master) HEAD@{2}: commit (initial): initial commit
```

削除されませんでした。

調べたところ `reflog` の参照がデフォルトで 90 日間保持されるため、`git gc --prune=now` を実行しても `reflog` に残っているコミットは削除されないようです。

先に `reflog` を失効させます。

```bash
$ git reflog expire --expire-unreachable=now --all
$ git reflog --all
4ab7f18 (HEAD -> master) refs/heads/master@{0}: commit (initial): initial commit
4ab7f18 (HEAD -> master) HEAD@{0}: commit (initial): initial commit
```

この時点ではフラグを含む commit や blob オブジェクト自体は残っています。

```bash
$ git fsck --unreachable
Checking ref database: 100% (1/1), done.
Checking object directories: 100% (256/256), done.
Checking objects: 100% (5/5), done.
unreachable commit 0f622f8b786c6a3654d7ccf305fcbc5fb4d63652
unreachable blob 52f951bcdaf8fd87c5f6b235347d7995fe5554dd
unreachable tree d4c445df9dfe60eda42fbfb7db64426ea62b9e92
Verifying commits in commit graph: 100% (1/1), done.

$ git show 52f951bcdaf8fd87c5f6b235347d7995fe5554dd
Alpaca{dummy}
```

`git gc --prune=now` を実行すればフラグを含むオブジェクトも削除されます。

```bash
$ git gc --prune=now
Enumerating objects: 2, done.
Counting objects: 100% (2/2), done.
Writing objects: 100% (2/2), done.
Total 2 (delta 0), reused 1 (delta 0), pack-reused 0 (from 0)

$ git show 52f951bcdaf8fd87c5f6b235347d7995fe5554dd
fatal: bad object 52f951bcdaf8fd87c5f6b235347d7995fe5554dd
```
