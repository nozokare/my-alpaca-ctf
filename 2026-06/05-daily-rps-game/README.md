# RPS GAME

https://alpacahack.com/daily/challenges/rps-game

## 問題の概要

サーバーと 1000 回じゃんけんを行い、600 回以上勝てばフラグが得られます。

サーバーが出す手は次のように `shuffle` を繰り返し適用した `hands` の最初の要素から決まります。

```python
HANDS = ["r", "p", "s"]

def shuffle(items):
    return sorted(items, key=lambda _: random.getrandbits(1))

hands = HANDS[:]
for i in range(ROUNDS):
    hands = shuffle(hands)
    opponent = hands[0]  # サーバーが出す手
    ...
```

## 方針を考える

Python の `random` は MT19937 を使用していて、内部状態は 19937 ビットあります。

一方じゃんけんで使用されるのは 3000 ビットなので、出力を予測するのは難しそうです。

`shuffle` がちゃんとシャッフルしているか怪しいので、出力の統計を見てみます。

```python
counters = {}
hands = HANDS[:]
for i in range(1000000):
    hands = shuffle(hands)
    hands_str = "".join(hands)
    counters[hands_str] = counters.get(hands_str, 0) + 1
counters
# =>
# {'srp': 166588,
#  'spr': 167269,
#  'psr': 167622,
#  'prs': 166698,
#  'rsp': 165727,
#  'rps': 166096}
```

各 hands の出現回数は均等のようです。

入力と出力の相関はどうでしょうか？

```python
counters = {}
hands = HANDS[:]
last_hans = None
for i in range(1000000):
    hands = shuffle(hands)
    hands_str = "".join(hands)
    if last_hans is not None:
        counters[f"{last_hans} => {hands_str}"] = counters.get(f"{last_hans} => {hands_str}", 0) + 1
    last_hans = hands_str
sorted(counters.items(), key=lambda x: x[0], reverse=True)
# =>
# [('srp => srp', 82425),
#  ('srp => spr', 20601),
#  ('srp => rsp', 21194),
#  ('srp => rps', 20599),
#  ('srp => psr', 20746),
#  ('spr => srp', 20853),
#  ('spr => spr', 84162),
#  ('spr => rsp', 20920),
#  ('spr => psr', 20804),
#  ('spr => prs', 20890),
#  ...
#  ('prs => prs', 84137)]
```

こちらは偏りがありますね。

入力と出力が同じになる確率が高くなっているようです。

## 解法

サーバーは前回と同じ手を出す確率が高いので、サーバーが直前に出した手に勝つ手を出し続けます。

```python
from pwn import remote

conn = remote(host, int(port))

HANDS = [b"r", b"p", b"s"]
ROUNDS = 1000

hand = b"r"
for i in range(ROUNDS):
    conn.sendlineafter(b"> ", hand)
    conn.recvuntil(b"Opponent: ")
    opponent = conn.recv(1)
    hand = HANDS[(HANDS.index(opponent) + 1) % 3]
    conn.recvuntil(b"Win count: ")
    win_count = conn.recvline().decode().strip()
    print(f"Round: {i + 1}, Win count: {win_count}")

print(conn.recvall().decode())
```

サーバーが出した手をもとに次の手を決めるので 1000 往復の通信が必要で結構時間がかかります。

運が悪いと負けることもありますが、何度か試せばフラグが得られました。


## 静的な解析

なぜ `shuffle` に偏りがあるのか考えてみます。

`sorted` は `key` が返す値を比較して安定ソートを行う関数で、今回は `random.getrandbits(1)` がランダムに返す 0 / 1 をキーにソートしています。

3 要素のリストの並び替えは $3! = 6$ 通りありますが、キーは $2^3 = 8$ 通りあるので、偏りなく並び替えることはできません。

実際、キーが `000`, `001`, `011`, `111` の場合は既にソートされた順番なので入力と出力は同じになりなります。

また、`b0 > b1 > b2` になるようなビットの並びは存在しないため、`ABC => CBA` のように逆順に並べ替えるキーは存在しません。

状態遷移確率をまとめると

- ABC => ABC: 4/8
- ABC => ACB: 1/8
- ABC => BAC: 1/8
- ABC => BCA: 1/8
- ABC => CAB: 1/8
- ABC => CBA: 0

のようになっており、1文字目が一致する確率は 5/8 = 62.5% となります。

1000 回中 600 回以上 1文字目が一致する確率は 95% 以上あるので、失敗したのはそこそこ運が悪かったようです。
