## Utility Scripts

### new-challenge.sh

新しい challenge の準備をまとめて行うスクリプトです。

- `{yyyy-mm}/{dd}-{type}-{slug}/` 配下に challenge ディレクトリを作成
- main を起点にしたブランチ（`{type}-{yyyymmdd}`）を作成・切り替え
- `writeup.md` のテンプレートを生成（VS Code で開く）
- handout ファイルのダウンロード（`.tar.gz` は自動展開）
- 接続情報を `.env` に保存

**デフォルト（非対話）**

```bash
./scripts/new-challenge.sh -t daily -T "Challenge Title"
```

必要なオプションをすべて引数で渡すと、入力待ちなしで完了します。
`--date` を省略すると今日の日付が使われます。

**対話モード**

```bash
./scripts/new-challenge.sh -i
```

`-i` / `--interactive` を指定すると、指定されていないオプションを対話で入力できます。

**オプション一覧**

| オプション                    | 説明                                        |
| ----------------------------- | ------------------------------------------- |
| `-t`, `--type <daily\|bside>` | challenge の種別（非対話時は必須）          |
| `-d`, `--date <yyyymmdd>`     | 日付（省略時: 今日）                        |
| `-T`, `--title <title>`       | タイトル。slug を自動生成（非対話時は必須） |
| `-u`, `--url <url>`           | handout のダウンロード URL（省略可）        |
| `-c`, `--connect <string>`    | 接続文字列。`.env` に保存（省略可）         |
| `-i`, `--interactive`         | 未指定オプションを対話で入力                |
| `--no-open`                   | VS Code で `writeup.md` を開かない          |

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
