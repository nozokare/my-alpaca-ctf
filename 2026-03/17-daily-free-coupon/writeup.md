# Free Coupon

## 問題

sessionでサーバー側に保存されている `balance` が 30 以上の状態で `/buy` にアクセスするとFLAGが出力される。

`/redeem` にアクセスすると `balance` が 10 増えるが、一度アクセスすると `redeemed` が `true` になり、以降アクセスしても `balance` は増えない。

## 解法

`/redeem` に短時間に複数回アクセスすることで、`redeemed` が `true` にセットされる前に `redeemed` の検査を通過することができ、`balance` を複数回増やすことができる。

具体的には、ブラウザで対象ページを開き、Developer Toolsで

```javascript
for (let i = 0; i < 3; i++) fetch("/redeem");
```

を実行し、その後 `/buy` にアクセスするとFLAGが出力される。
