# guess.js

https://alpacahack.com/daily/challenges/guessjs

## 問題の概要

nodejs サーバーで入力した `guess` が次のように処理されます。

```js
Function(
  guess,
  `
    if (${SECRET} === 1337) {
      return process.env.FLAG;
    } else {
      return "Failed...";
    }
  `,
)(1337);
```

`guess` に入力する値を工夫して環境変数の `FLAG` を出力させる問題です。

## 解法

`Function` コンストラクタは `Function(arg1, ..., argN, functionBody)` の形式で呼び出されると、

```js
`function(${args.join(",")}) {
  ${functionBody}
}`;
```

のような関数を生成します。引数は `"a, b"` のように複数の引数をカンマ区切りで渡したり、`"a = 1"` のように引数にデフォルト値を指定することもできます。

デフォルト値は関数呼び出し時に引数が渡されなかったときに評価されるため、`"a, b = console.log(process.env.FLAG)"` のような文字列を入力するとフラグを出力させることができます。
