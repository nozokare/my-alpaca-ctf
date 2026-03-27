## Utility Scripts

### new-challenge.ts

新しい challenge の準備をまとめて行うスクリプトです。

- `{yyyy-mm}/{dd}-{type}-{slug}/` 配下に challenge ディレクトリを作成
- main を起点にしたブランチ（`{type}-{yyyymmdd}`）を作成・切り替え
- `README.md` を生成し、`handout` 内の主要ファイルとあわせて VS Code で開く
- handout を自動ダウンロード（`.tar.gz` は自動展開）
- `CONNECT=` を書いた `.env` を生成

公開ページの情報から `type`・`date`・`title`・`slug`・attachments を自動で決定します。

```bash
node ./scripts/new-challenge.ts --url https://alpacahack.com/daily/challenges/alpacker
```

URL を省略した場合は `-i` / `--interactive` を付けると対話入力できます。

```bash
node ./scripts/new-challenge.ts -i
```

**オプション一覧**

| オプション           | 説明 |
| -------------------- | ---- |
| `-u`, `--url <url>`  | AlpacaHack の challenge URL |
| `-i`, `--interactive` | URL 未指定時に対話入力する |
| `--no-open`          | VS Code でファイルを開かない |
| `-h`, `--help`       | ヘルプを表示 |

---

### rebase-branches.sh

main にマージされていないローカルブランチをすべて main に rebase するスクリプトです。

```bash
./scripts/rebase-branches.sh
```

コンフリクトが発生したブランチは `rebase --abort` でスキップし、残りを続行します。
完了後は元のブランチに戻ります。

**オプション一覧**

| オプション        | 説明                              |
| ----------------- | --------------------------------- |
| `-n`, `--dry-run` | rebase せずに対象ブランチだけ表示 |

---

### check-publish-dates.sh

challenge の公開禁止期間を確認するスクリプトです。

- **daily**: 出題日の翌日から公開可能
- **bside**: 出題日の4日後から公開可能

公開可能日より前の challenge ディレクトリがリポジトリに含まれていれば、その challenge を BLOCKED と判定します。

**スタンドアロン実行**

```bash
./scripts/check-publish-dates.sh          # HEAD を確認
./scripts/check-publish-dates.sh <ref>    # 任意の treeish を確認
```

**pre-push フックを設定**

```bash
npm install
```

を実行すると `LeftHook` を使ったフックがインストールされます。
