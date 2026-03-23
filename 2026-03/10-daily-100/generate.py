def try_prefix(prefix):
    for l00 in ["100", "10_0", "1_00", "1_0_0"]:
        for sign in ["", "+"]:
            c = sign + prefix + l00
            if len(c) <= 10.0:
                print(f"{c}")

try_prefix("")
for n in range(1, 8):
    for i in range(1 << n):
        try_prefix(f"{i:0{n}b}".replace("1", "0_"))
