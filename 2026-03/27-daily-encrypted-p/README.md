# encrypted-p

https://alpacahack.com/daily/challenges/encrypted-p

## 問題の概要

RSA 暗号で暗号化された文字列を復号する問題です。

```python
m = bytes_to_long(os.getenv("FLAG", "Alpaca{REDACTED}").encode())
p = getPrime(512)
q = getPrime(512)
n = p * q
e = 65537
c1 = pow(m, e, n)
c2 = pow(p, e, n)
```

与えられているのは `n`, `e`, `c1`, `c2` の4つの値です。

## 解法

`p` と `q` が分かれば `m` を復号できます。とりあえず `n` を素因数分解してみます。

```bash
cut -d= -f2 handout/output.txt | head -n1 | factor
```

当然ですが無理そうですね。

`c2 = pow(p, e, n)` がヒントになりそうです。とりあえず `gcd` を取ってみます。

```python
print(math.gcd(c2, n))
# => 12963287280031...
```

因数が見つかりました。

$c_2$ は $p^e$ を $n = p \cdot q$ で割った余りです。すなわち、ある $k\in\mathbb{N}$ が存在して

$$
p^e = p \cdot q \cdot k + c_2
$$

が成り立ちます。左辺は $p$ の倍数なので、 $c_2$ も $p$ の倍数になります。

$p$ と $q$ は互いに素なので、 $\gcd(c_2, n)$ を取ると $p$ が得られます。

あとは `p` と `q` を求めて、RSA の復号の手順を踏むだけです。

```python
p = math.gcd(n, c2)
q = n // p

phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)
m = pow(c1, d, n)

print(bytes.fromhex(hex(m)[2:]).decode())
```

Python だと `pow` で逆元も取れるので楽ですね。

## n の素因数分解にはどのくらいの時間がかかるのか?

$p$, $q$ は 512 ビットの素数なので、 $n$ は 1024 ビットの整数になります。

実用上は RSA-1024 は安全ではないとは言われていますが、実際は素因数分解にどのくらいの時間がかかるのでしょうか?

調べてみたところ、[RSA Factoring Challenge](https://en.wikipedia.org/wiki/RSA_Factoring_Challenge) で素因数分解されている最大の数は RSA250 (10 進数で 250 桁、829 ビット) でした。

CADO-NFS という一般数体篩法の実装を使って、RSA250 を素因数分解するのに 2700 コア年かかったそうです。

https://sympa.inria.fr/sympa/arc/cado-nfs/2020-02/msg00001.html

`c2` が与えられていなければ大変なことになるところでした。
