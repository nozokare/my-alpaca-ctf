
ulong main(int argc,char **argv,char **envp)

{
    int iVar1;
    int64_t iVar2;
    uchar *puVar3;
    ulong uVar4;
    code *s1_00;
    int64_t in_FS_OFFSET;
    int64_t var_b8h;
    char *var_b0h;
    size_t var_a8h;
    void *s1;
    void *var_98h;
    char *s;
    int64_t canary;
    
    canary = *(in_FS_OFFSET + 0x28);
    sym.imp.printf("flag: ");
    iVar2 = sym.imp.fgets(&s,0x80,_reloc.stdin);
    if (iVar2 == 0) {
        uVar4 = 1;
    }
    else {
        puVar3 = sym.imp.strchr(&s,10);
        if (puVar3 != NULL) {
            *puVar3 = 0;
        }
        iVar2 = sym.imp.strlen(&s);
        if (iVar2 == 0x24) {
            s1_00 = sym.imp.mmap(NULL,0x11b,7,0x22,-1,0);
            if (s1_00 == 0xffffffffffffffff) {
                uVar4 = 1;
            }
            else {
                sym.imp.memcpy(s1_00,0x4020,0x11b);
                for (var_b8h._0_4_ = 0; var_b8h < 0x11b; var_b8h._0_4_ = var_b8h + 1) {
                    s1_00[var_b8h] = s1_00[var_b8h] * 's';
                }
                iVar1 = (*s1_00)(&s);
                if (iVar1 == 0) {
                    sym.imp.puts("wrong...");
                }
                else {
                    sym.imp.puts("correct!");
                }
                uVar4 = 0;
            }
        }
        else {
            sym.imp.puts("wrong...");
            uVar4 = 0;
        }
    }
    if (canary != *(in_FS_OFFSET + 0x28)) {
    //WARNING: Subroutine does not return
        sym.imp.__stack_chk_fail();
    }
    return uVar4;
}

