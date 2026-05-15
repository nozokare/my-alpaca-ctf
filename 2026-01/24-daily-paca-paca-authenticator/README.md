# Paca Paca Authenticator

https://alpacahack.com/daily/challenges/paca-paca-authenticator

## 問題の概要

`{"name": "alpaca", "message": "paca paca!"}` のような認証情報が AES-256-CBC で暗号化されて保持されています。

ただし、`iv` はデバッグ情報として表示されて忘れられ、`ciphertext` だけが保存されています。

その後、代わりにユーザーが入力した `iv` を使用して認証情報を復号して JSON としてパースし、`name` が `llama` であればフラグが表示されます。

## 解法

### AES-CBC での復号処理

AES はブロック単位で暗号化・復号を行います｡ $i$ ブロック目の平文を $P_i$ 、暗号文を $C_i$ 、鍵 $K$ で決まる復号関数を $D_K$ とすると、AES-CBC での復号は次のように表されます。

$$P_i = D_K(C_i) \oplus C_{i-1}$$

<p align="center">
<img alt="AES-CBCの処理" src="../../2026-02/26-daily-one-byte-padding-oracle-attack/aes-cbc.png" height="240px" />
</p>

ただし、最初のブロック $C_0$ は初期化ベクトル $IV$ です。

$$P_1 = D_K(C_1) \oplus IV$$

$IV$ のビットを反転させると先頭ブロックの平文 $P_1$ の同じ位置のビットを反転させることができます。

また、$IV$ を変えても後続のブロックの復号結果には影響を与えないので、残りのデータやパディングは正しいままにしておくことができます。

### 認証情報を書き換える

認証情報の先頭ブロック(16バイト)は

```
{"name": "alpaca
```

です。`name` を `llama` にすればよいので、

```
{"name":  "llama
```

に書き換えれば認証に成功します。

## 解答に使用したコード

```python
from pwn import remote, xor

conn = remote(host, port)

iv = bytes.fromhex(conn.recvline().strip().decode().split(" ")[-1])
flip = xor(b'{"name": "alpaca', b'{"name":  "llama')
new_iv = xor(iv, flip)

conn.sendlineafter(b"> ", new_iv.hex().encode())
print(conn.recvall().decode())
```
