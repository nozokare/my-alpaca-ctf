# FLAG OVER

https://alpacahack.com/daily/challenges/flag-over

## 問題の概要

接続すると `bash -i` を起動する Python サーバーが動いています。
フラグは環境変数の `FLAG` に入っていますが、`bash` 起動時に他の値に上書きされてしまいます。

## 解法

自由にコマンドを実行できるので、`ps` コマンドで `python` プロセスの PID を調べ、`/proc/<PID>/environ` を読むことでフラグを得ることができます。
