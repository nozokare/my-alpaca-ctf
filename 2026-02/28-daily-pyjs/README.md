# pyjs

https://alpacahack.com/daily/challenges/pyjs

## 問題の概要

Python で実行すると `I LOVE ALPACA` と出力され、Node.js で実行すると `I LOVE SECCON` と出力されるコードを入力するとフラグがもらえる問題です。

## 解法

`//` Python では整数除算の演算子ですが、JavaScript ではそれ以降がコメントになります。
`\r` は `input()` で入力の終わりとしては認識されませんが、両方の言語で改行として機能するため、実質的に複数行のコードを入力することができます。

したがって、以下のテキストで改行を`\r`に置き換えて入力すれば両方の言語で別々の出力が得られます。

```text:input.txt
0 // 1; print("I LOVE ALPACA"); exit(0)
console.log("I LOVE SECCON")
```

## 実行方法

```bash
(sed -z 's/\n/\r/g' input.txt && echo ) | nc localhost 1337
```
