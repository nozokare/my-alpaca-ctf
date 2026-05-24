# curl as a service 2

https://alpacahack.com/daily/challenges/curl-as-a-service-2

## 問題の概要

curl に渡すと "Give me a flag" という文字列が接続先に送られるような URL を入力するとフラグが得られる問題です。

## 解法

受け取ったデータを標準出力に表示するサーバーを

```
socat TCP-LISTEN:1337,reuseaddr,fork -
```

で立てて、[man page](https://curl.se/docs/manpage.html) にあるプロトコルを

```
curl ****://localhost:1337/
```

でいろいろ試してみたところ、gopher プロトコルでパスに指定した文字列の2文字目以降がサーバーに送られるようでした。

## 解答に使用した入力

```
gopher://secret:1337//Give%20me%20a%20flag
```
