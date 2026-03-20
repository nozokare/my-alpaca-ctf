# Find XOR key

https://alpacahack.com/daily/challenges/find-xor-key

## 問題の概要

フラグを暗号化した HEX 文字列を解読する Crypto 問題です。

`[a-zA-Z]{7}` の形の `key` をランダムに生成し、`cycle` で拡張した `key` とフラグを XOR したものを HEX 文字列に変換したものが与えられています。

## 解法

フラグの先頭が `Alpaca{` であることが分かっているため、先頭 7 バイトを使って `key` を復元できます。その後、`cycle` を使って `key` を拡張し、フラグ全体を復号します。

## 解答に使用したコード

[decode.py](decode.py)
