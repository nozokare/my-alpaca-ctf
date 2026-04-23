# Camelid Match

https://alpacahack.com/daily/challenges/camelid-match

## 問題の概要

Alice と Bob がある動物を好きかどうかが

```python
a = secrets.randbelow(2)
b = secrets.randbelow(2)
```

で決められ、次の `row(a, b)` で符号化された文字列をみて、Alice と Bob が両方ともその動物が好きか、どちらか一方でも好きでないかを当てる問題です。

```python
YES = '♡♧'
NO = '♧♡'
MID = '♡'

def rot(s, k):
    k %= len(s)
    return s[k:] + s[:k]

def enc(bit):
    return YES if bit else NO

def row(a, b):
    s = enc(a) + MID + enc(b)
    s = s[1] + s[0] + s[2:]
    return rot(s, secrets.randbelow(5))
```

10 回連続で正解するとフラグが出力されます。

## 解法

人力で出力をみて YES-YES っぽいかどうかで y/n を入力していくとフラグが得られました。

カスすぎる解法なのでもうすこしまともな方法を考えます。

原理的にこの問題が解けるためには YES-YES のときの符号とその他の場合の符号は分離されているはずです。

実際、YES/NO の全組み合わせで `rot` する前の文字列 `s` を考えると

| Alice | Bob | `s`     |
| ----- | --- | ------- |
| YES   | YES | `♧♡♡♡♧` |
| YES   | NO  | `♧♡♡♧♡` |
| NO    | YES | `♡♧♡♡♧` |
| NO    | NO  | `♡♧♡♧♡` |

となっており、`rot` した文字列を繰り返したときに `♡♡♡` や `♧♧` が出現するのは YES-YES のときだけであることがわかります。

YES-NO/NO-YES/NO-NO の符号はすべて `♡♧♡♧♡` の回転であるため、この 3 パターンのどれだったかまでは区別できませんが、YES-YES かそれ以外かは判定できます。

## 実装

```python
from pwn import remote

conn = remote(host, port)

while (line := conn.recvline()).endswith(b"(y/n)\n"):
    cards = conn.recvline().decode()[-6:-1]
    conn.sendline(b"y" if "♡♡♡" in (cards + cards) else b"n")

print(line.decode())
```

## 元ネタについて

ヒントによると、この問題は The Five-Card Trick という論理積を秘密計算するカードベースのプロトコルをもとにしているそうです。

- [カード組を用いた秘密計算](https://www.jstage.jst.go.jp/article/essfr/9/3/9_179/_pdf)

## もっと邪道な解法

答えが `"n"` になる確率は 3/4 で、10 回連続で `"n"` になる確率は約 5.6% です。

したがって、ひたすら `"n"` を入力し続けるだけでもそんなに多くない試行回数でフラグが得られます。

```bash
$ while ! yes n | python chall.py | grep Alpaca; do echo -n .; done
..................> Alpaca{dummy}
```
