table = [
    [13, 2],
    [21, 3],
    [22, 0],
    [19, 6],
    [19, 1],
    [19, 6],
    [24, 4],
    [13, 5],
    [21, 0],
    [23, 6],
    [21, 0],
    [23, 3],
    [21, 0],
    [22, 6],
    [22, 5],
    [19, 4],
    [19, 0],
    [24, 2],
    [19, 4],
    [15, 0],
    [23, 5],
    [21, 3],
    [23, 4],
    [21, 0],
    [22, 0],
    [21, 3],
    [21, 0],
    [19, 1],
    [19, 6],
    [23, 4],
    [21, 0],
    [22, 6],
    [22, 5],
    [25, 6],
]

def is_correct_byte(x, exptected):
    y = (x * 3435973837) >> 34
    t = (x * 613566757) >> 32
    z = x - ((((x - t) >> 1) + t) >> 2) * 7

    return y == exptected[0] and z == exptected[1]

buf = []
for expected in table:
    for x in range(256):
        if is_correct_byte(x, expected):
            buf.append(x)
            break

print(bytes(buf))
