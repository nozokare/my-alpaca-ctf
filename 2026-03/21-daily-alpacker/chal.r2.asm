            ; DATA XREF from entry0 @ 0x1158(r)
┌ 482: int main (int argc, char **argv, char **envp);
│ afv: vars(8:sp[0x10..0xc0])
│           0x00001229      f30f1efa       endbr64
│           0x0000122d      55             push rbp
│           0x0000122e      4889e5         mov rbp, rsp
│           0x00001231      4881ecc000..   sub rsp, 0xc0
│           0x00001238      64488b0425..   mov rax, qword fs:[0x28]
│           0x00001241      488945f8       mov qword [canary], rax
│           0x00001245      31c0           xor eax, eax
│           0x00001247      488d05b60d..   lea rax, str.flag:        ; 0x2004 ; "flag:"
│           0x0000124e      4889c7         mov rdi, rax              ; const char *format
│           0x00001251      b800000000     mov eax, 0
│           0x00001256      e8b5feffff     call sym.imp.printf       ; int printf(const char *format)
│           0x0000125b      488b15de2e..   mov rdx, qword [obj.stdin] ; [0x4140:8]=0 ; FILE *stream
│           ;-- rip:
│           0x00001262      488d8570ff..   lea rax, [s]
│           0x00001269      be80000000     mov esi, 0x80             ; int size
│           0x0000126e      4889c7         mov rdi, rax              ; char *s
│           0x00001271      e8aafeffff     call sym.imp.fgets        ; char *fgets(char *s, int size, FILE *stream)
│           0x00001276      4885c0         test rax, rax
│       ┌─< 0x00001279      7431           je 0x12ac
│       │   0x0000127b      488d8570ff..   lea rax, [s]
│       │   0x00001282      be0a000000     mov esi, 0xa              ; int c
│       │   0x00001287      4889c7         mov rdi, rax              ; const char *s
│       │   0x0000128a      e871feffff     call sym.imp.strchr       ; char *strchr(const char *s, int c)
│       │   0x0000128f      48898550ff..   mov qword [var_b0h], rax
│       │   0x00001296      4883bd50ff..   cmp qword [var_b0h], 0
│      ┌──< 0x0000129e      7416           je 0x12b6
│      ││   0x000012a0      488b8550ff..   mov rax, qword [var_b0h]
│      ││   0x000012a7      c60000         mov byte [rax], 0
│     ┌───< 0x000012aa      eb0a           jmp 0x12b6
│     │││   ; CODE XREF from main @ 0x1279(x)
│     ││└─> 0x000012ac      b801000000     mov eax, 1
│     ││┌─< 0x000012b1      e93f010000     jmp 0x13f5
│     │││   ; CODE XREFS from main @ 0x129e(x), 0x12aa(x)
│     └└──> 0x000012b6      488d8570ff..   lea rax, [s]
│       │   0x000012bd      4889c7         mov rdi, rax              ; const char *s
│       │   0x000012c0      e80bfeffff     call sym.imp.strlen       ; size_t strlen(const char *s)
│       │   0x000012c5      48898558ff..   mov qword [var_a8h], rax
│       │   0x000012cc      4883bd58ff..   cmp qword [var_a8h], 0x24 ; '$'
│      ┌──< 0x000012d4      7419           je 0x12ef
│      ││   0x000012d6      488d052e0d..   lea rax, str.wrong...     ; 0x200b ; "wrong..."
│      ││   0x000012dd      4889c7         mov rdi, rax              ; const char *s
│      ││   0x000012e0      e8dbfdffff     call sym.imp.puts         ; int puts(const char *s)
│      ││   0x000012e5      b800000000     mov eax, 0
│     ┌───< 0x000012ea      e906010000     jmp 0x13f5
│     │││   ; CODE XREF from main @ 0x12d4(x)
│     │└──> 0x000012ef      41b900000000   mov r9d, 0                ; size_t offset
│     │ │   0x000012f5      41b8ffffffff   mov r8d, 0xffffffff       ; -1 ; int fd
│     │ │   0x000012fb      b922000000     mov ecx, 0x22             ; '\"' ; int flags
│     │ │   0x00001300      ba07000000     mov edx, 7                ; int prot
│     │ │   0x00001305      be1b010000     mov esi, 0x11b            ; size_t length
│     │ │   0x0000130a      bf00000000     mov edi, 0                ; void*addr
│     │ │   0x0000130f      e8dcfdffff     call sym.imp.mmap         ; void*mmap(void*addr, size_t length, int prot, int flags, int fd, size_t offset)
│     │ │   0x00001314      48898560ff..   mov qword [s1], rax
│     │ │   0x0000131b      4883bd60ff..   cmp qword [s1], 0xffffffffffffffff
│     │┌──< 0x00001323      750a           jne 0x132f
│     │││   0x00001325      b801000000     mov eax, 1
│    ┌────< 0x0000132a      e9c6000000     jmp 0x13f5
│    ││││   ; CODE XREF from main @ 0x1323(x)
│    ││└──> 0x0000132f      488b8560ff..   mov rax, qword [s1]
│    ││ │   0x00001336      ba1b010000     mov edx, 0x11b            ; size_t n
│    ││ │   0x0000133b      488d0dde2c..   lea rcx, [0x00004020]
│    ││ │   0x00001342      4889ce         mov rsi, rcx              ; const void *s2
│    ││ │   0x00001345      4889c7         mov rdi, rax              ; void *s1
│    ││ │   0x00001348      e8e3fdffff     call sym.imp.memcpy       ; void *memcpy(void *s1, const void *s2, size_t n)
│    ││ │   0x0000134d      c78548ffff..   mov dword [var_b8h], 0
│    ││┌──< 0x00001357      eb3a           jmp 0x1393
│    ││││   ; CODE XREF from main @ 0x139e(x)
│   ┌─────> 0x00001359      8b8548ffffff   mov eax, dword [var_b8h]
│   ╎││││   0x0000135f      4863d0         movsxd rdx, eax
│   ╎││││   0x00001362      488b8560ff..   mov rax, qword [s1]
│   ╎││││   0x00001369      4801d0         add rax, rdx
│   ╎││││   0x0000136c      0fb600         movzx eax, byte [rax]
│   ╎││││   0x0000136f      8b9548ffffff   mov edx, dword [var_b8h]
│   ╎││││   0x00001375      4863ca         movsxd rcx, edx
│   ╎││││   0x00001378      488b9560ff..   mov rdx, qword [s1]
│   ╎││││   0x0000137f      4801ca         add rdx, rcx
│   ╎││││   0x00001382      b973000000     mov ecx, 0x73             ; 's'
│   ╎││││   0x00001387      0fafc1         imul eax, ecx
│   ╎││││   0x0000138a      8802           mov byte [rdx], al
│   ╎││││   0x0000138c      838548ffff..   add dword [var_b8h], 1
│   ╎││││   ; CODE XREF from main @ 0x1357(x)
│   ╎││└──> 0x00001393      8b8548ffffff   mov eax, dword [var_b8h]
│   ╎││ │   0x00001399      3d1a010000     cmp eax, 0x11a
│   └─────< 0x0000139e      76b9           jbe 0x1359
│    ││ │   0x000013a0      488b8560ff..   mov rax, qword [s1]
│    ││ │   0x000013a7      48898568ff..   mov qword [var_98h], rax
│    ││ │   0x000013ae      488d8570ff..   lea rax, [s]
│    ││ │   0x000013b5      488b9568ff..   mov rdx, qword [var_98h]
│    ││ │   0x000013bc      4889c7         mov rdi, rax
│    ││ │   0x000013bf      ffd2           call rdx
│    ││ │   0x000013c1      89854cffffff   mov dword [var_b4h], eax
│    ││ │   0x000013c7      83bd4cffff..   cmp dword [var_b4h], 0
│    ││┌──< 0x000013ce      7411           je 0x13e1
│    ││││   0x000013d0      488d053d0c..   lea rax, str.correct_     ; 0x2014 ; "correct!"
│    ││││   0x000013d7      4889c7         mov rdi, rax              ; const char *s
│    ││││   0x000013da      e8e1fcffff     call sym.imp.puts         ; int puts(const char *s)
│   ┌─────< 0x000013df      eb0f           jmp 0x13f0
│   │││││   ; CODE XREF from main @ 0x13ce(x)
│   │││└──> 0x000013e1      488d05230c..   lea rax, str.wrong...     ; 0x200b ; "wrong..."
│   │││ │   0x000013e8      4889c7         mov rdi, rax              ; const char *s
│   │││ │   0x000013eb      e8d0fcffff     call sym.imp.puts         ; int puts(const char *s)
│   │││ │   ; CODE XREF from main @ 0x13df(x)
│   └─────> 0x000013f0      b800000000     mov eax, 0
│    ││ │   ; CODE XREFS from main @ 0x12b1(x), 0x12ea(x), 0x132a(x)
│    └└─└─> 0x000013f5      488b55f8       mov rdx, qword [canary]
│           0x000013f9      64482b1425..   sub rdx, qword fs:[0x28]
│       ┌─< 0x00001402      7405           je 0x1409
│       │   0x00001404      e8d7fcffff     call sym.imp.__stack_chk_fail ; void stack_chk_fail(void)
│       │   ; CODE XREF from main @ 0x1402(x)
│       └─> 0x00001409      c9             leave
└           0x0000140a      c3             ret
