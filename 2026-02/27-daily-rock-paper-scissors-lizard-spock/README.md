# Rock Paper Scissors Lizard Spock

https://alpacahack.com/daily/challenges/rock-paper-scissors-lizard-spock

## 問題の概要

Signed Cookie で状態を管理している Node.js アプリケーションで、じゃんけんで 100 回連続で勝つとフラグが得られる問題です。

じゃんけんの手は `"rock", "paper", "scissors", "lizard", "spock"` の 5 種類になっています。

`/rpsls` に出す手を POST すると、サーバーでランダムに選ばれた手と比較して勝敗が判定されます。
勝つと `streak` が 1 増え、負けるかあいこになると `streak` が 0 にリセットされます。

`streak` が 100 以上の状態で `/` にアクセスするとフラグが出力されます。

状態は Cookie で管理されており、Cookie の値は `cookie-parser` の `signed` オプションをつけて署名されています。

## 解法

Cookie を改竄することはできませんが、リプレイ攻撃は可能です。

`streak=n` の状態の Cookie を使って `/rpsls` に挑戦し、勝った場合は `streak=n+1` の状態の Cookie が得られます。
負けた場合も `streak=n` の Cookie で再度 `/rpsls` に挑戦できるため、勝つまでリプレイ可能です。

これを `streak=100` になるまで繰り返せばフラグが得られます。

## 回答に使用したコード

- [exploit.ts](./exploit.ts)
