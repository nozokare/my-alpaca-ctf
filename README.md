# AlpacaHack Daily CTF Solutions

<https://alpacahack.com/> の解答を置いておく個人的なリポジトリです。

## ディレクトリ構造

```
{yyyy-mm}/               # 年月（例: 2026-03/）
  {dd}-{type}-{slug}/    # 日付・種別・slug（例: 08-daily-guess-js/）
    handout/             # 配布ファイル（gitignore 対象）
    README.md            # 解法メモ
    .env                 # 接続情報 CONNECT=... （gitignore 対象）
    <その他の解答ファイル>
```

- `type`: `daily` | `bside`
- ブランチ名は `{type}-{yyyymmdd}`（例: `daily-20260308`）

## Docker ツール用 npm scripts

問題を解くためのツール用の Docker イメージをビルド・起動するための npm scripts を用意しています。

- [sage](https://www.sagemath.org/)
- [radare2](https://rada.re/n/radare2.html)
- [pwndbg](https://pwndbg.com/)

コンテナ起動時にコマンドを実行したディレクトリが `/workdir` にマウントされ、コンテナ内で作業ディレクトリとして使用されます。

### SageMath

#### Jupyter Notebook を起動

`npm run sage:jupyter`

Port=8754 で Jupyter Notebook が起動します。
`$REPO_ROOT/.env` に `JUPYTER_TOKEN=...` を設定しておくと、Jupyter Notebook にアクセスする際のトークンとして使用されます。

VSCode で `.ipynb` ファイルを開き、`http://host.docker.internal:8754/?token={JUPYTER_TOKEN}` に接続すると SageMath カーネルを使用できます。

#### SageMath を実行

`npm run sage:run ./file.sage` で `/workdir` にマウントされた `./file.sage` を SageMath で実行できます。

### radare2

- `npm run radare2:build`: `containers/radare2.dockerfile` をビルド
- `npm run radare2:run ./chall`: `/workdir` にマウントされた `./chall` を `r2` で開く
- `npm run radare2:run -- -A ./chall`: `-A` オプションを付けて `r2` で開く(自動解析を実行)

### pwndbg

- `npm run pwndbg:build`: `containers/pwndbg.dockerfile` をビルド
- `npm run pwndbg:run ./chall`: `/workdir` にマウントされた `./chall` を `gdb` で開く
