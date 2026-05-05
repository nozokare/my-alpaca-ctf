Dump of assembler code for function main:
   0x0000000000401178 <+0>:     endbr64
   0x000000000040117c <+4>:     push   rbp
   0x000000000040117d <+5>:     mov    rbp,rsp
   0x0000000000401180 <+8>:     sub    rsp,0x20
   0x0000000000401184 <+12>:    lea    rax,[rip+0xe79]        # 0x402004
   0x000000000040118b <+19>:    mov    rdi,rax
   0x000000000040118e <+22>:    call   0x401060 <puts@plt>
   0x0000000000401193 <+27>:    mov    rdx,QWORD PTR [rip+0x2ea6]        # 0x404040 <stdin@GLIBC_2.2.5>
   0x000000000040119a <+34>:    lea    rax,[rbp-0x20]
   0x000000000040119e <+38>:    mov    esi,0x48
   0x00000000004011a3 <+43>:    mov    rdi,rax
   0x00000000004011a6 <+46>:    call   0x401080 <fgets@plt>
   0x00000000004011ab <+51>:    mov    eax,0x0
   0x00000000004011b0 <+56>:    leave
   0x00000000004011b1 <+57>:    ret
