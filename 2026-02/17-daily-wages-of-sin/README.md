# wages of sin()

https://alpacahack.com/daily/challenges/wages-of-sin

## 問題の概要

`sin()` 関数の評価結果が異なるような環境を答える問題です。

サーバーでは次のように入力した環境変数をセットして QEMU で `chall` を実行しています。

```python
import os

key, value = input("env key: "), input("env value: ")
os.environ[key] = value
if os.system("qemu-x86_64 -cpu Skylake-Client-v3,-xsavec ./chall") == 0:
    print("Alpaca{*** REDACTED ***}")
```

`chall` は `sin(0.253936121155405) == 0.2512157895691234` になるかどうかを判定する C プログラムです。

環境変数をうまくセットして `sin()` の評価結果を変えるとフラグが出力されます。

## 解法を考える

`chall` を disassemble してみましたが、そのまま `glibc` の `sin()` を呼び出しているようでした。(それはそう)

したがって、解答は次のどちらかになるだろうと考えました。

1. QEMU の設定を環境変数で与えて CPU エミュレーションの挙動を変える
2. `glibc` が環境変数を参照して `sin()` の計算方法が変わるようにする

1.については、`sin()` を計算する命令の実行結果が CPU によって異なり、QEMU の設定で厳密に同じように計算するかどうかを切り替えられるのではないかと考えました。

QEMU のドキュメントを確認したところ、`-accel tcg`/`-accel kvm` で FPU の計算をエミュレートするかどうかを切り替えられるようですが、環境変数を参照する設定項目がほとんどないため、この方法ではないようです。

2.については、`glibc` に数値計算の精度を犠牲にして高速化できるような設定を環境変数で与えることができるのではないかと考えました。

(QEMU を Virtual Box のような仮想マシンだと思っていたので、ホストの環境変数が全てゲストに渡されるのは非直感的でしたが、それはフルシステムエミュレーションモードの QEMU の挙動でした。
ユーザーモード QEMU はゲスト ELF を QEMU のプロセス内で実行するエミュレータとして動作ため、`getenv()` が呼び出されるとホストの環境変数を参照することになります。)

調べたところ(というかChatGPTに聞いたところ)、`GLIBC_TUNABLES` という環境変数で `glibc.cpu.hwcaps` を設定することで CPU が対応している SIMD 命令の検出を上書きすることができるようです。

`glibc` では IFUNC（Indirect Function） という機構を使って実行時に CPU 機能をチェックして最適な実装を選択するようになっています。

`GLIBC_TUNABLES=glibc.cpu.hwcaps=-AVX2` のように設定すると `sin()` の計算に AVX2 命令が使用されなくなり、近似多項式や評価順序による丸め誤差が変わる影響で異なる結果が得られることがあります。

## 回答に使用した入力

```
env key: GLIBC_TUNABLES
env value: glibc.cpu.hwcaps=-AVX2
Wow, we got 0.2512157895691233!
Alpaca{*** REDACTED ***}
```

## 感想

ただの知識問題に見えてしまい、知らない内容だったので早々に ChatGPT に聞いてしまいましたが、作者の rsk0315 さんの Writeup を読むと `sin()` の実装に立ち入る REV 問題だったようで、もう少し自力で考えてみるべきだったなと思いました。

説明文で `sin()` の実装や IFUNC に言及したり、配布に関連するソースコードを同梱する or README にリンクを貼るなど、もう少し誘導があれば想定のルートに乗りやすかったかなと思います。
