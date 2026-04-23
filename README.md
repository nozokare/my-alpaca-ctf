# AlpacaHack Daily CTF Solutions

<https://alpacahack.com/> の解答を置いておく個人的なリポジトリです。

## ディレクトリ構造

```
{yyyy-mm}/               # 年月（例: 2026-03/）
  {dd}-{type}-{slug}/    # 日付・種別・スラッグ（例: 08-daily-guess-js/）
    handout/             # 配布ファイル（gitignore 対象）
    README.md            # 解法メモ
    .env                 # 接続情報 CONNECT=... （gitignore 対象）
    <その他の解答ファイル>
```

- `type`: `daily` | `bside`
- ブランチ名は `{type}-{yyyymmdd}`（例: `daily-20260308`）
