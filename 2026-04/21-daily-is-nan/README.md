# is NaN?

https://alpacahack.com/daily/challenges/is-nan

## 問題の概要

double として解釈したときに NaN になるような 64 ビットの値で、16 進数で表現したときに `"deadbeef"` を含むものを入力するとフラグが表示される問題です。

## 解法

IEEE 754 の double 型は、符号ビット 1 ビット、指数部 11 ビット、仮数部 52 ビットで構成されます。

指数部の全ビットが 1 のときは特別な値を表し、仮数部が 0 のときは ±Inf を、仮数部が 0 以外のときは NaN を表します。

## 回答に使用した入力

```
0xffffffffdeadbeef
```
