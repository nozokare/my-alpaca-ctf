# read-a-binary

https://alpacahack.com/daily/challenges/read-a-binary

## 問題の概要

フラグチェッカーが受け付ける正しいフラグを特定する REV 問題です。

## 解法

radare2/r2ghidra でバイナリを逆アセンブル・逆コンパイルしてみたところ、入力した文字列とローカル変数領域に 1 バイトずつセットした文字列を比較しているようです。

```
....
│           0x004011af      e8ccfeffff     call sym.imp.__isoc99_scanf ; int scanf(const char *format, ...)
; string "AlpacaDec...................."
│           0x004011b4      c68530ffff..   mov byte [var_d0h], 0x41    ; 'A' ; 65
│           0x004011bb      c68531ffff..   mov byte [var_cfh], 0x6c    ; 'l' ; 108
│           0x004011c2      c68532ffff..   mov byte [var_ceh], 0x70    ; 'p' ; 112
│           0x004011c9      c68533ffff..   mov byte [var_cdh], 0x61    ; 'a' ; 97
│           0x004011d0      c68534ffff..   mov byte [var_cch], 0x63    ; 'c' ; 99
│           0x004011d7      c68535ffff..   mov byte [var_cbh], 0x61    ; 'a' ; 97
│           0x004011de      c68536ffff..   mov byte [var_cah], 0x7b    ; '{' ; 123
│           0x004011e5      c68537ffff..   mov byte [var_c9h], 0x44    ; 'D' ; 68
│           0x004011ec      c68538ffff..   mov byte [var_c8h], 0x65    ; 'e' ; 101
│           0x004011f3      c68539ffff..   mov byte [var_c7h], 0x63    ; 'c' ; 99
...
```

バッファの内容が string として解釈されて表示されていたので(なぜか`{}`が無視されていますが)、これをコピーして提出しました。
