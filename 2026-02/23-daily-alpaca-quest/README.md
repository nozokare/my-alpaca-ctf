# Alpaca Quest

https://alpacahack.com/daily/challenges/alpaca-quest

## 解法

apk ファイルは zip 形式であるため、解凍して中身を確認します。

```bash
unzip alpaca-quest.apk -d alpaca-quest
```

apk ファイルの構造に疎いので、どのファイルに注目すればいいのか分かりませんでした…

読めないバイナリファイルが多いので、tar でまとめて文字列を抽出してみます。

```
tar -cf - alpaca-quest/ | strings | grep Alpaca
```

フラグが見つかってしまいました。
