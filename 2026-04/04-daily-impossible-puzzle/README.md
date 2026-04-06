# Impossible Puzzle

https://alpacahack.com/daily/challenges/impossible-puzzle

## 問題の概要

PHP で長さが異なるが `$A == $B` となるような文字列を入力するとフラグが得られる問題です。

## 解法

PHP では数値形式の文字列は比較前に数値に変換されるため、`"1" == "01"` などは `true` となります。

## 参考

https://www.php.net/manual/ja/language.operators.comparison.php
