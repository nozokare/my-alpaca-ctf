# AlpacaHack Daily CTF Solutions

<https://alpacahack.com/> の回答を置いておく個人的なリポジトリです。

## Utilities

次のコマンドで challenge ディレクトリ作成、main 起点の branch 作成、ファイルダウンロード、接続情報保存をまとめて行えます。

```bash
npm run alpaca:new
```

入力項目:

- `type`: `daily` or `bside`
- `date`: `yyyymmdd` 形式で入力
- `title`: 入力文字列から slug を自動生成（小文字・ハイフン区切り）
- `url`: 任意。`.tar.gz` のときは challenge 配下の `.src` に展開
- `connect`: 任意。`CONNECT=<string>` を challenge 配下の `.env` に保存
