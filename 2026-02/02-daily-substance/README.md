# Substance

https://alpacahack.com/daily/challenges/substance

## 問題の概要

フラグに次のようにランダムな数をかけた結果からフラグを復元する問題です。

```python
flag = int.from_bytes(os.getenv("FLAG", "Alpaca{REDACTED}").encode(), "big")
print(flag * randint(2, 2026) * randint(2, 2026) * randint(2, 2026))
print(flag * randint(2, 2026) * randint(2, 2026) * randint(2, 2026))
```

## 解法

`result1 = flag * A`、`result2 = flag * B` とすると、2 つの整数の GCD をとると

`gcd(result1, result2) = flag * gcd(A, B)`

となり、2 つの乱数のうちたまたま重複した因数(小さい可能性が高い)以外を消すことができます。

```python
import math

flag = math.gcd(result1, result2)
print(flag.to_bytes(math.ceil(flag.bit_length() / 8), "big"))
# => b'\x04\x99\x9f\xe6\xd8\xfc\xda\xaeei\x9f\x9e\xb4\xfdS\xaf\xc3E \xb6\x85hB\n\xb5\x9fi/\x9e\xca'
```

`gcd(A, B)` の寄与を消し切れなかったので、`flag` の約数を確認してみます。

```python
import sympy
print(sympy.factorint(flag))
# => {2: 1, 3: 4, 269: 1, 503821: 1, 4572850661: 1, 316224362225539763970988074867563404070815390505801: 1}
```

`gcd(A, B)` は小さい因数だと思われますが、そんなにパターンが多くなさそうなので雑に全ての約数を確認します。末尾が `}` になる約数がフラグの候補になります。

```python
import sympy
for f in sympy.divisors(flag):
    if f & 0xFF == ord("}"):
        print(f.to_bytes(math.ceil(f.bit_length() / 8), "big"))
# => b'Alpaca{........}'
```

無事にフラグが得られました。
