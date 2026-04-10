
read.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	48 83 ec 20          	sub    $0x20,%rsp
   4:	48 b8 2f 66 6c 61 67 	movabs $0x78742e67616c662f,%rax
   b:	2e 74 78 
   e:	48 89 44 24 8e       	mov    %rax,-0x72(%rsp)
  13:	66 c7 44 24 96 74 00 	movw   $0x74,-0x6a(%rsp)
  1a:	48 8d 7c 24 8e       	lea    -0x72(%rsp),%rdi
  1f:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  25:	b8 02 00 00 00       	mov    $0x2,%eax
  2a:	44 89 c6             	mov    %r8d,%esi
  2d:	44 89 c2             	mov    %r8d,%edx
  30:	0f 05                	syscall
  32:	89 c7                	mov    %eax,%edi
  34:	48 8d 74 24 98       	lea    -0x68(%rsp),%rsi
  39:	ba 80 00 00 00       	mov    $0x80,%edx
  3e:	44 89 c0             	mov    %r8d,%eax
  41:	0f 05                	syscall
  43:	89 c2                	mov    %eax,%edx
  45:	b8 01 00 00 00       	mov    $0x1,%eax
  4a:	89 c7                	mov    %eax,%edi
  4c:	0f 05                	syscall
  4e:	b8 00 00 00 00       	mov    $0x0,%eax
  53:	48 83 c4 20          	add    $0x20,%rsp
  57:	c3                   	ret
