# hit-and-miss

https://alpacahack.com/daily/challenges/hit-and-miss

## 問題の概要

フラグが入力した正規表現にマッチするかどうかを判定してくれるサーバーが動いています。

フラグの形式は `ALPACA{\w+}` で、`\w+` の部分は `[0-9a-zA-Z_]` から構成される文字列です。

## 解法

分かっている部分に続く次の文字がどれであるかを二分探索で特定していきます。

使用可能な文字列すべてを含む配列 `charset[]` を作成し、`Alpaca\\{[' + "".join(charset[0:m]) + ']'` のような正規表現をサーバーに送ります。
`charset[0:m]` だとマッチしないが `charset[0:m+1]` だとマッチする場合、次の文字は `charset[m]` であることが分かります。

## 解答に使用したコード

- [solve.py](solve.py)
