# Tar Uploader

https://alpacahack.com/daily/challenges/tar-uploader

## 問題の概要

アップロードされた tar ファイルをサーバー上に展開する Flask ベースの Python サーバーが動いています。

アップロードすると UUID が発行され、サーバー上の `/app/static/<UUID>/` に展開されたファイルが配置されます。レスポンスで UUID が知らされ、`http://<server>/static/<UUID>/<file name>` にアクセスすれば展開されたファイルを閲覧できます。

`/flag.txt` の内容を読み取ればフラグが得られます。

## 解法

`/flag.txt` を指すシンボリックリンクを tar ファイルに入れてアップロードすれば、展開されたファイルを通じてフラグを読み取ることができます。
