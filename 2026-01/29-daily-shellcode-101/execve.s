.global _start

.section .text
_start:
  endbr64
  sub    $0x8,%rsp
  mov    $0x68732f6e69622f, %rax  # "/bin/sh"
  mov    %rax, -0x8(%rsp)
  lea    -0x8(%rsp), %rdi   # arg1 = "/bin/sh"
  mov    $0x0, %rsi         # arg2 = NULL
  mov    $0x0, %rdx         # arg3 = NULL
  mov    $0x3b, %rax        # syscall number for execve
  syscall                   # call kernel
