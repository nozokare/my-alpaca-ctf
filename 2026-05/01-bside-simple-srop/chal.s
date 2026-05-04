x/4i win-16
   0x555555555270 <win-16>:     pop    rax
   0x555555555271 <win-15>:     ret
   0x555555555272 <win-14>:     syscall
   0x555555555274 <win-12>:     ret

Dump of assembler code for function win:
   0x0000555555555280 <+0>:     endbr64
   0x0000555555555284 <+4>:     movabs rax,0x68732f6e69622f
   0x000055555555528e <+14>:    sub    rsp,0x18
   0x0000555555555292 <+18>:    mov    QWORD PTR [rsp+0x8],rax
   0x0000555555555297 <+23>:    movabs rax,0xdeadbeefcafebabe
   0x00005555555552a1 <+33>:    cmp    rdi,rax
   0x00005555555552a4 <+36>:    jne    0x5555555552d1 <win+81>
   0x00005555555552a6 <+38>:    lea    rdi,[rip+0xd5b]        # 0x555555556008
   0x00005555555552ad <+45>:    call   0x5555555550a0 <puts@plt>
   0x00005555555552b2 <+50>:    lea    rdi,[rip+0xd7f]        # 0x555555556038
   0x00005555555552b9 <+57>:    call   0x5555555550a0 <puts@plt>
   0x00005555555552be <+62>:    lea    rdi,[rsp+0x8]
   0x00005555555552c3 <+67>:    xor    edx,edx
   0x00005555555552c5 <+69>:    xor    esi,esi
   0x00005555555552c7 <+71>:    call   0x5555555550c0 <execve@plt>
   0x00005555555552cc <+76>:    add    rsp,0x18
   0x00005555555552d0 <+80>:    ret
   0x00005555555552d1 <+81>:    mov    rdx,rdi
   0x00005555555552d4 <+84>:    lea    rsi,[rip+0xd85]        # 0x555555556060
   0x00005555555552db <+91>:    mov    edi,0x2
   0x00005555555552e0 <+96>:    xor    eax,eax
   0x00005555555552e2 <+98>:    call   0x5555555550e0 <__printf_chk@plt>
   0x00005555555552e7 <+103>:   mov    edi,0x1
   0x00005555555552ec <+108>:   call   0x5555555550f0 <exit@plt>

Dump of assembler code for function main:
   0x0000555555555100 <+0>:     endbr64
   0x0000555555555104 <+4>:     sub    rsp,0x48
   0x0000555555555108 <+8>:     lea    rdx,[rip+0x171]        # 0x555555555280 <win>
   0x000055555555510f <+15>:    lea    rsi,[rip+0xf85]        # 0x55555555609b
   0x0000555555555116 <+22>:    xor    eax,eax
   0x0000555555555118 <+24>:    mov    edi,0x2
   0x000055555555511d <+29>:    call   0x5555555550e0 <__printf_chk@plt>
   0x0000555555555122 <+34>:    lea    rsi,[rip+0xf8f]        # 0x5555555560b8
   0x0000555555555129 <+41>:    mov    edi,0x2
   0x000055555555512e <+46>:    xor    eax,eax
   0x0000555555555130 <+48>:    call   0x5555555550e0 <__printf_chk@plt>
   0x0000555555555135 <+53>:    mov    rdi,rsp
   0x0000555555555138 <+56>:    xor    eax,eax
   0x000055555555513a <+58>:    call   0x5555555550d0 <gets@plt>
   0x000055555555513f <+63>:    xor    eax,eax
   0x0000555555555141 <+65>:    add    rsp,0x48
   0x0000555555555145 <+69>:    ret
