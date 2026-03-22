set disassemble-next-line auto

display/wx $rbp-0x74
display/c $rbp-0x75
display/128bx $rbp-0x70

# main()
b main
# scanf("%u", &n);
#b *main+233
# scanf(" %c", &c);
#b *main+277
# memset
b *main+303
b *main+308
