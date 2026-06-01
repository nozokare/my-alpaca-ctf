# Cache Me If You Can

https://alpacahack.com/daily/challenges/cache-me-if-you-can

## 問題の概要

Flask サーバーで `GET /flag` に 2 回アクセスするとフラグが表示されます。

ただし、アクセスは Nginx のリバースプロキシ経由で行われ、1 回目のアクセスの結果が 1 年間キャッシュされます。

```conf
proxy_cache_path /var/cache/nginx/proxy keys_zone=flag_cache:10m inactive=365d;

server {
    listen 80;

    location / {
        proxy_pass http://app:8000;
        proxy_cache flag_cache;
        proxy_cache_valid 200 365d;
    }
}
```

## 解法

リクエストパラメータをつけると Nginx は別のページとみなしてキャッシュを分けるため、
`/flag` と `/flag?a` にアクセスすればサーバーに 2 回アクセスすることができます。
