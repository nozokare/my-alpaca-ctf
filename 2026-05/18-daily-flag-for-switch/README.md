# Flag for Switch

https://alpacahack.com/daily/challenges/flag-for-switch

## 問題の概要

Node.js サーバーで、`User-Agent` ヘッダーに `Switch` を指定して `/` にアクセスするとフラグが得られます。

## 解法に使用したコード

```bash
curl -H "User-Agent: Switch" http://localhost:3000/
```
