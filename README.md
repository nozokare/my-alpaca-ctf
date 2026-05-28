# AlpacaHack Daily CTF Solutions

<https://alpacahack.com/> の解答を置いておく個人的なリポジトリです。

## ディレクトリ構造

```
{yyyy-mm}/               # 年月（例: 2026-03/）
  {dd}-{type}-{slug}/    # 日付・種別・slug（例: 08-daily-guess-js/）
    handout/             # 配布ファイル（gitignore 対象）
    README.md            # 解法メモ
    .env                 # 接続情報 CONNECT=... （gitignore 対象）
    <その他の解答ファイル>
```

- `type`: `daily` | `bside`
- ブランチ名は `{type}-{yyyymmdd}`（例: `daily-20260308`）

## Docker ツール用 npm scripts

問題を解くためのツール用の Docker イメージをビルド・起動するための npm scripts を用意しています。

- [SageMath](https://www.sagemath.org/)
- [PyPy](https://www.pypy.org/)
- [radare2](https://rada.re/n/radare2.html)
- [pwndbg](https://pwndbg.com/)
- [ILSpyCmd](https://github.com/icsharpcode/ILSpy/tree/master/ICSharpCode.ILSpyCmd)

コンテナ起動時にコマンドを実行したディレクトリが `/workdir` にマウントされ、コンテナ内で作業ディレクトリとして使用されます。

### SageMath

- `npm run sage:run ./file.sage`: `/workdir` にマウントされた `./file.sage` を SageMath で実行
- `npm run sage:install-kernel`: Jupyter カーネルとして Docker で SageMath を起動する構成をインストール

### PyPy

- `npm run pypy:build`: `containers/pypy-jupyter.dockerfile` をビルド
- `npm run pypy:run ./file.py`: `/workdir` にマウントされた `./file.py` を PyPy で実行
- `npm run pypy:install-kernel`: Jupyter カーネルとして Docker で PyPy を起動する構成をインストール

### radare2

- `npm run radare2:build`: `containers/radare2.dockerfile` をビルド
- `npm run radare2:run ./chall`: `/workdir` にマウントされた `./chall` を `r2` で開く
- `npm run radare2:run -- -A ./chall`: `-A` オプションを付けて `r2` で開く(自動解析を実行)

### pwndbg

- `npm run pwndbg:build`: `containers/pwndbg.dockerfile` をビルド
- `npm run pwndbg:run ./chall`: `/workdir` にマウントされた `./chall` を `gdb` で開く

### ILSpyCmd

- `npm run ilspycmd:build`: `containers/ilspycmd.dockerfile` をビルド
- `npm run ilspycmd:run -- ./AlpacaForm.dll`: `/workdir` にマウントされた .NET バイナリを `ilspycmd` で解析
