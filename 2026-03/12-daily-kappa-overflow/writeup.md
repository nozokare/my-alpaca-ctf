# kappa overflow

## 問題の概要

サーバーで動いてる C言語プログラムの処理の途中で `UnhandledException` を発生させるとフラグが出力される問題です。

## 解法

```C
struct {
    char buf[64];
    volatile int *target;
} cache;
```

に対し、

```C
getchar(cache.buf);
*chache.target = 1;
```

が実行されます。 `getchar` の入力の長さが制限されていないため、`cache.buf` に 64 バイト以上の入力を与えると `cache.target` を上書きできます。

`cache.target` を不正なアドレスを指すように書き換え、`*cache.target = 1` を実行させると範囲外アクセスが発生し、フラグが出力されます。

## 解答に使用した入力

```
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```
