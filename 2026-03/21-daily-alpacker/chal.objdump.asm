
chal:     file format elf64-x86-64


Disassembly of section .init:

0000000000001000 <.init>:
    1000:	f3 0f 1e fa          	endbr64
    1004:	48 83 ec 08          	sub    $0x8,%rsp
    1008:	48 8b 05 d9 2f 00 00 	mov    0x2fd9(%rip),%rax        # 3fe8 <memcpy@plt+0x2eb8>
    100f:	48 85 c0             	test   %rax,%rax
    1012:	74 02                	je     1016 <__cxa_finalize@plt-0x9a>
    1014:	ff d0                	call   *%rax
    1016:	48 83 c4 08          	add    $0x8,%rsp
    101a:	c3                   	ret

Disassembly of section .plt:

0000000000001020 <.plt>:
    1020:	ff 35 62 2f 00 00    	push   0x2f62(%rip)        # 3f88 <memcpy@plt+0x2e58>
    1026:	f2 ff 25 63 2f 00 00 	bnd jmp *0x2f63(%rip)        # 3f90 <memcpy@plt+0x2e60>
    102d:	0f 1f 00             	nopl   (%rax)
    1030:	f3 0f 1e fa          	endbr64
    1034:	68 00 00 00 00       	push   $0x0
    1039:	f2 e9 e1 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    103f:	90                   	nop
    1040:	f3 0f 1e fa          	endbr64
    1044:	68 01 00 00 00       	push   $0x1
    1049:	f2 e9 d1 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    104f:	90                   	nop
    1050:	f3 0f 1e fa          	endbr64
    1054:	68 02 00 00 00       	push   $0x2
    1059:	f2 e9 c1 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    105f:	90                   	nop
    1060:	f3 0f 1e fa          	endbr64
    1064:	68 03 00 00 00       	push   $0x3
    1069:	f2 e9 b1 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    106f:	90                   	nop
    1070:	f3 0f 1e fa          	endbr64
    1074:	68 04 00 00 00       	push   $0x4
    1079:	f2 e9 a1 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    107f:	90                   	nop
    1080:	f3 0f 1e fa          	endbr64
    1084:	68 05 00 00 00       	push   $0x5
    1089:	f2 e9 91 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    108f:	90                   	nop
    1090:	f3 0f 1e fa          	endbr64
    1094:	68 06 00 00 00       	push   $0x6
    1099:	f2 e9 81 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    109f:	90                   	nop
    10a0:	f3 0f 1e fa          	endbr64
    10a4:	68 07 00 00 00       	push   $0x7
    10a9:	f2 e9 71 ff ff ff    	bnd jmp 1020 <__cxa_finalize@plt-0x90>
    10af:	90                   	nop

Disassembly of section .plt.got:

00000000000010b0 <__cxa_finalize@plt>:
    10b0:	f3 0f 1e fa          	endbr64
    10b4:	f2 ff 25 3d 2f 00 00 	bnd jmp *0x2f3d(%rip)        # 3ff8 <memcpy@plt+0x2ec8>
    10bb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

Disassembly of section .plt.sec:

00000000000010c0 <puts@plt>:
    10c0:	f3 0f 1e fa          	endbr64
    10c4:	f2 ff 25 cd 2e 00 00 	bnd jmp *0x2ecd(%rip)        # 3f98 <memcpy@plt+0x2e68>
    10cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000010d0 <strlen@plt>:
    10d0:	f3 0f 1e fa          	endbr64
    10d4:	f2 ff 25 c5 2e 00 00 	bnd jmp *0x2ec5(%rip)        # 3fa0 <memcpy@plt+0x2e70>
    10db:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000010e0 <__stack_chk_fail@plt>:
    10e0:	f3 0f 1e fa          	endbr64
    10e4:	f2 ff 25 bd 2e 00 00 	bnd jmp *0x2ebd(%rip)        # 3fa8 <memcpy@plt+0x2e78>
    10eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000010f0 <mmap@plt>:
    10f0:	f3 0f 1e fa          	endbr64
    10f4:	f2 ff 25 b5 2e 00 00 	bnd jmp *0x2eb5(%rip)        # 3fb0 <memcpy@plt+0x2e80>
    10fb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001100 <strchr@plt>:
    1100:	f3 0f 1e fa          	endbr64
    1104:	f2 ff 25 ad 2e 00 00 	bnd jmp *0x2ead(%rip)        # 3fb8 <memcpy@plt+0x2e88>
    110b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001110 <printf@plt>:
    1110:	f3 0f 1e fa          	endbr64
    1114:	f2 ff 25 a5 2e 00 00 	bnd jmp *0x2ea5(%rip)        # 3fc0 <memcpy@plt+0x2e90>
    111b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001120 <fgets@plt>:
    1120:	f3 0f 1e fa          	endbr64
    1124:	f2 ff 25 9d 2e 00 00 	bnd jmp *0x2e9d(%rip)        # 3fc8 <memcpy@plt+0x2e98>
    112b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001130 <memcpy@plt>:
    1130:	f3 0f 1e fa          	endbr64
    1134:	f2 ff 25 95 2e 00 00 	bnd jmp *0x2e95(%rip)        # 3fd0 <memcpy@plt+0x2ea0>
    113b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

Disassembly of section .text:

0000000000001140 <.text>:
    1140:	f3 0f 1e fa          	endbr64
    1144:	31 ed                	xor    %ebp,%ebp
    1146:	49 89 d1             	mov    %rdx,%r9
    1149:	5e                   	pop    %rsi
    114a:	48 89 e2             	mov    %rsp,%rdx
    114d:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
    1151:	50                   	push   %rax
    1152:	54                   	push   %rsp
    1153:	45 31 c0             	xor    %r8d,%r8d
    1156:	31 c9                	xor    %ecx,%ecx
    1158:	48 8d 3d ca 00 00 00 	lea    0xca(%rip),%rdi        # 1229 <memcpy@plt+0xf9>
    115f:	ff 15 73 2e 00 00    	call   *0x2e73(%rip)        # 3fd8 <memcpy@plt+0x2ea8>
    1165:	f4                   	hlt
    1166:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    116d:	00 00 00 
    1170:	48 8d 3d c9 2f 00 00 	lea    0x2fc9(%rip),%rdi        # 4140 <stdin@GLIBC_2.2.5>
    1177:	48 8d 05 c2 2f 00 00 	lea    0x2fc2(%rip),%rax        # 4140 <stdin@GLIBC_2.2.5>
    117e:	48 39 f8             	cmp    %rdi,%rax
    1181:	74 15                	je     1198 <memcpy@plt+0x68>
    1183:	48 8b 05 56 2e 00 00 	mov    0x2e56(%rip),%rax        # 3fe0 <memcpy@plt+0x2eb0>
    118a:	48 85 c0             	test   %rax,%rax
    118d:	74 09                	je     1198 <memcpy@plt+0x68>
    118f:	ff e0                	jmp    *%rax
    1191:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1198:	c3                   	ret
    1199:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    11a0:	48 8d 3d 99 2f 00 00 	lea    0x2f99(%rip),%rdi        # 4140 <stdin@GLIBC_2.2.5>
    11a7:	48 8d 35 92 2f 00 00 	lea    0x2f92(%rip),%rsi        # 4140 <stdin@GLIBC_2.2.5>
    11ae:	48 29 fe             	sub    %rdi,%rsi
    11b1:	48 89 f0             	mov    %rsi,%rax
    11b4:	48 c1 ee 3f          	shr    $0x3f,%rsi
    11b8:	48 c1 f8 03          	sar    $0x3,%rax
    11bc:	48 01 c6             	add    %rax,%rsi
    11bf:	48 d1 fe             	sar    $1,%rsi
    11c2:	74 14                	je     11d8 <memcpy@plt+0xa8>
    11c4:	48 8b 05 25 2e 00 00 	mov    0x2e25(%rip),%rax        # 3ff0 <memcpy@plt+0x2ec0>
    11cb:	48 85 c0             	test   %rax,%rax
    11ce:	74 08                	je     11d8 <memcpy@plt+0xa8>
    11d0:	ff e0                	jmp    *%rax
    11d2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    11d8:	c3                   	ret
    11d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    11e0:	f3 0f 1e fa          	endbr64
    11e4:	80 3d 5d 2f 00 00 00 	cmpb   $0x0,0x2f5d(%rip)        # 4148 <stdin@GLIBC_2.2.5+0x8>
    11eb:	75 2b                	jne    1218 <memcpy@plt+0xe8>
    11ed:	55                   	push   %rbp
    11ee:	48 83 3d 02 2e 00 00 	cmpq   $0x0,0x2e02(%rip)        # 3ff8 <memcpy@plt+0x2ec8>
    11f5:	00 
    11f6:	48 89 e5             	mov    %rsp,%rbp
    11f9:	74 0c                	je     1207 <memcpy@plt+0xd7>
    11fb:	48 8b 3d 06 2e 00 00 	mov    0x2e06(%rip),%rdi        # 4008 <memcpy@plt+0x2ed8>
    1202:	e8 a9 fe ff ff       	call   10b0 <__cxa_finalize@plt>
    1207:	e8 64 ff ff ff       	call   1170 <memcpy@plt+0x40>
    120c:	c6 05 35 2f 00 00 01 	movb   $0x1,0x2f35(%rip)        # 4148 <stdin@GLIBC_2.2.5+0x8>
    1213:	5d                   	pop    %rbp
    1214:	c3                   	ret
    1215:	0f 1f 00             	nopl   (%rax)
    1218:	c3                   	ret
    1219:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1220:	f3 0f 1e fa          	endbr64
    1224:	e9 77 ff ff ff       	jmp    11a0 <memcpy@plt+0x70>
    1229:	f3 0f 1e fa          	endbr64
    122d:	55                   	push   %rbp
    122e:	48 89 e5             	mov    %rsp,%rbp
    1231:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
    1238:	64 48 8b 04 25 28 00 	mov    %fs:0x28,%rax
    123f:	00 00 
    1241:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    1245:	31 c0                	xor    %eax,%eax
    1247:	48 8d 05 b6 0d 00 00 	lea    0xdb6(%rip),%rax        # 2004 <memcpy@plt+0xed4>
    124e:	48 89 c7             	mov    %rax,%rdi
    1251:	b8 00 00 00 00       	mov    $0x0,%eax
    1256:	e8 b5 fe ff ff       	call   1110 <printf@plt>
    125b:	48 8b 15 de 2e 00 00 	mov    0x2ede(%rip),%rdx        # 4140 <stdin@GLIBC_2.2.5>
    1262:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
    1269:	be 80 00 00 00       	mov    $0x80,%esi
    126e:	48 89 c7             	mov    %rax,%rdi
    1271:	e8 aa fe ff ff       	call   1120 <fgets@plt>
    1276:	48 85 c0             	test   %rax,%rax
    1279:	74 31                	je     12ac <memcpy@plt+0x17c>
    127b:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
    1282:	be 0a 00 00 00       	mov    $0xa,%esi
    1287:	48 89 c7             	mov    %rax,%rdi
    128a:	e8 71 fe ff ff       	call   1100 <strchr@plt>
    128f:	48 89 85 50 ff ff ff 	mov    %rax,-0xb0(%rbp)
    1296:	48 83 bd 50 ff ff ff 	cmpq   $0x0,-0xb0(%rbp)
    129d:	00 
    129e:	74 16                	je     12b6 <memcpy@plt+0x186>
    12a0:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
    12a7:	c6 00 00             	movb   $0x0,(%rax)
    12aa:	eb 0a                	jmp    12b6 <memcpy@plt+0x186>
    12ac:	b8 01 00 00 00       	mov    $0x1,%eax
    12b1:	e9 3f 01 00 00       	jmp    13f5 <memcpy@plt+0x2c5>
    12b6:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
    12bd:	48 89 c7             	mov    %rax,%rdi
    12c0:	e8 0b fe ff ff       	call   10d0 <strlen@plt>
    12c5:	48 89 85 58 ff ff ff 	mov    %rax,-0xa8(%rbp)
    12cc:	48 83 bd 58 ff ff ff 	cmpq   $0x24,-0xa8(%rbp)
    12d3:	24 
    12d4:	74 19                	je     12ef <memcpy@plt+0x1bf>
    12d6:	48 8d 05 2e 0d 00 00 	lea    0xd2e(%rip),%rax        # 200b <memcpy@plt+0xedb>
    12dd:	48 89 c7             	mov    %rax,%rdi
    12e0:	e8 db fd ff ff       	call   10c0 <puts@plt>
    12e5:	b8 00 00 00 00       	mov    $0x0,%eax
    12ea:	e9 06 01 00 00       	jmp    13f5 <memcpy@plt+0x2c5>
    12ef:	41 b9 00 00 00 00    	mov    $0x0,%r9d
    12f5:	41 b8 ff ff ff ff    	mov    $0xffffffff,%r8d
    12fb:	b9 22 00 00 00       	mov    $0x22,%ecx
    1300:	ba 07 00 00 00       	mov    $0x7,%edx
    1305:	be 1b 01 00 00       	mov    $0x11b,%esi
    130a:	bf 00 00 00 00       	mov    $0x0,%edi
    130f:	e8 dc fd ff ff       	call   10f0 <mmap@plt>
    1314:	48 89 85 60 ff ff ff 	mov    %rax,-0xa0(%rbp)
    131b:	48 83 bd 60 ff ff ff 	cmpq   $0xffffffffffffffff,-0xa0(%rbp)
    1322:	ff 
    1323:	75 0a                	jne    132f <memcpy@plt+0x1ff>
    1325:	b8 01 00 00 00       	mov    $0x1,%eax
    132a:	e9 c6 00 00 00       	jmp    13f5 <memcpy@plt+0x2c5>
    132f:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
    1336:	ba 1b 01 00 00       	mov    $0x11b,%edx
    133b:	48 8d 0d de 2c 00 00 	lea    0x2cde(%rip),%rcx        # 4020 <memcpy@plt+0x2ef0>
    1342:	48 89 ce             	mov    %rcx,%rsi
    1345:	48 89 c7             	mov    %rax,%rdi
    1348:	e8 e3 fd ff ff       	call   1130 <memcpy@plt>
    134d:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%rbp)
    1354:	00 00 00 
    1357:	eb 3a                	jmp    1393 <memcpy@plt+0x263>
    1359:	8b 85 48 ff ff ff    	mov    -0xb8(%rbp),%eax
    135f:	48 63 d0             	movslq %eax,%rdx
    1362:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
    1369:	48 01 d0             	add    %rdx,%rax
    136c:	0f b6 00             	movzbl (%rax),%eax
    136f:	8b 95 48 ff ff ff    	mov    -0xb8(%rbp),%edx
    1375:	48 63 ca             	movslq %edx,%rcx
    1378:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
    137f:	48 01 ca             	add    %rcx,%rdx
    1382:	b9 73 00 00 00       	mov    $0x73,%ecx
    1387:	0f af c1             	imul   %ecx,%eax
    138a:	88 02                	mov    %al,(%rdx)
    138c:	83 85 48 ff ff ff 01 	addl   $0x1,-0xb8(%rbp)
    1393:	8b 85 48 ff ff ff    	mov    -0xb8(%rbp),%eax
    1399:	3d 1a 01 00 00       	cmp    $0x11a,%eax
    139e:	76 b9                	jbe    1359 <memcpy@plt+0x229>
    13a0:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
    13a7:	48 89 85 68 ff ff ff 	mov    %rax,-0x98(%rbp)
    13ae:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
    13b5:	48 8b 95 68 ff ff ff 	mov    -0x98(%rbp),%rdx
    13bc:	48 89 c7             	mov    %rax,%rdi
    13bf:	ff d2                	call   *%rdx
    13c1:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
    13c7:	83 bd 4c ff ff ff 00 	cmpl   $0x0,-0xb4(%rbp)
    13ce:	74 11                	je     13e1 <memcpy@plt+0x2b1>
    13d0:	48 8d 05 3d 0c 00 00 	lea    0xc3d(%rip),%rax        # 2014 <memcpy@plt+0xee4>
    13d7:	48 89 c7             	mov    %rax,%rdi
    13da:	e8 e1 fc ff ff       	call   10c0 <puts@plt>
    13df:	eb 0f                	jmp    13f0 <memcpy@plt+0x2c0>
    13e1:	48 8d 05 23 0c 00 00 	lea    0xc23(%rip),%rax        # 200b <memcpy@plt+0xedb>
    13e8:	48 89 c7             	mov    %rax,%rdi
    13eb:	e8 d0 fc ff ff       	call   10c0 <puts@plt>
    13f0:	b8 00 00 00 00       	mov    $0x0,%eax
    13f5:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
    13f9:	64 48 2b 14 25 28 00 	sub    %fs:0x28,%rdx
    1400:	00 00 
    1402:	74 05                	je     1409 <memcpy@plt+0x2d9>
    1404:	e8 d7 fc ff ff       	call   10e0 <__stack_chk_fail@plt>
    1409:	c9                   	leave
    140a:	c3                   	ret

Disassembly of section .fini:

000000000000140c <.fini>:
    140c:	f3 0f 1e fa          	endbr64
    1410:	48 83 ec 08          	sub    $0x8,%rsp
    1414:	48 83 c4 08          	add    $0x8,%rsp
    1418:	c3                   	ret
