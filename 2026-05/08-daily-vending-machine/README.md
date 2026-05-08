# Vending Machine

https://alpacahack.com/daily/challenges/vending-machine

## 問題の概要

自販機機能が実装されている `VendingMachine` クラスを利用して、ユーザーが入力したアイテムを購入する処理が行われます。

```python
def main():
    vm = VendingMachine()
    vm.print_menu()
    while True:
        mark = input("your choice> ").lower()
        if mark == "x":
            print("Bye.")
            break
        vm.buy(mark)
```

在庫はアイテムに対応する文字をアイテム数分繰り返した文字列で表されています。

```python
class VendingMachine:
    def __init__(self):
        self.stock = 'a'*30 + 'b'*60 + 'c'*20 + 'd'*50 + 'e'*40 + 'f' # 'aaa...eeef'
        self.item_names = {
            'a': 'apple juice',
            'b': 'banana juice',
            'c': 'coke',
            'd': 'draft beer',
            'e': 'energy drink',
            'f': 'flag'
        }
```

購入処理は `a` ～ `e` の 1 文字を入力すると在庫から対応するアイテムを 1 つ減らし、アイテム名を表示します。

```python
class VendingMachine:
    def buy(self, mark:str):
        # check choice
        if mark not in ['a', 'b', 'c', 'd', 'e']: # No 'f'? Hmm...
            print("Invalid choice.")
            return
        # check stock
        if len(self.stock) <= 0:
            print("All sold out.")
            return
        # find the location of the product
        loc = self.stock.find(mark)
        # take the product from stock
        stock_list = list(self.stock)
        item = stock_list.pop(loc)
        self.stock = ''.join(stock_list)
        # dispense the product
        name = self.item_names[item]
        print(f"You bought {name}.")
        if item == 'f':
            print(f"Flag:", FLAG)
        else:
            print("Thank you!")
```

`flag` を購入できればフラグが表示されますが、`f` を入力すると無効な選択として扱われます。

## 解法

[`sequence.pop`](https://docs.python.org/ja/3/library/stdtypes.html#sequence.pop) はリストから指定した位置の要素を削除し、その要素を返すメソッドです。

`-1` を指定すると最後の要素が対象になるため、`loc` を `-1` にできれば `stock_list.pop(loc)` で在庫の最後にある `f` を購入することができます。

[`str.find`](https://docs.python.org/ja/3/library/stdtypes.html#str.find) は文字列内で指定した値が最初に現れる位置を返すメソッドですが、見つからない場合は `-1` を返します。

したがって `self.stock` に出現しない文字列を指定できれば `loc = self.stock.find(mark)` を `-1` にすることができます。

しかし、`mark` は `mark not in ['a', 'b', 'c', 'd', 'e']` だと無効な選択肢として扱われてしまいます。

[`in`/`not in` 演算子](https://docs.python.org/ja/3/reference/expressions.html#membership-test-operations)は `__contains__()` で所属を判定しており、JavaScript で `"toString" in {"a":1, "b":1}` が `true` になってしまうようなガバはなさそうです。

### 在庫チェックに注目する

在庫チェックの実装をみてみると `len(self.stock) <= 0` で全ての在庫がなくなっているかどうかだけ確認しており、購入するアイテムが在庫に存在するかどうかは確認していません。

したがって 1 つのアイテムを購入し続けて在庫がなくなった状態でさらに購入しても処理が進んでしまい、`loc = self.stock.find(mark)` で `-1` が返されて `flag` を購入できます。

## 解答に使用したコード

```bash
yes c | head -n 21 | nc localhost 1337
```

## 感想

今回の問題の作問者が baumroll1234 さんということで、ちょっと楽しみにしていた問題でした。

(CTF 初心者とのことですが、積極的に Writeup を投稿されていて、個人的に勝手に応援している方の一人です)

一見 `flag` を購入できないように見えるが、処理を追っていくと見つかるバグらしいバグが仕込まれている問題で面白かったです。

自分も作問に興味があって考えているネタがいくつかあるので、いつか出題できたらなと思います。
