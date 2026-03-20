# mt19937 tempering function:
#   y ^= (y >> 11);
#   y ^= (y << 7) & 0x9d2c5680UL;
#   y ^= (y << 15) & 0xefc60000UL;
#   y ^= (y >> 18);

# y = x ^ (x >> 11)
#      x31 x30 x29 x28 x27 x26 x25 x24 x23 x22 x21 x20 x19 x18 x17 x16 x15 x14 x13 x12 x11 x10 x09 x08 x07 x06 x05 x04 x03 x02 x01 x00
# xor)                                             x31 x30 x29 x28 x27 x26 x25 x24 x23 x22 x21 x20 x19 x18 x17 x16 x15 x14 x13 x12 x11
#      y31 y30 y29 y28 y27 y26 y25 y24 y23 y22 y21 y20 y19 y18 y17 y16 y15 y14 y13 y12 y11 y10 y09 y08 y07 y06 y05 y04 y03 y02 y01 y00
# 
# x31 = y31,       ..., x21 = y21,
# x20 = y20 ^ x31, ..., x11 = y11 ^ x21  ... x[i] = y[i] ^ x[i + shift] (for i < n - shift)
# x10 = y10 ^ x20, ..., x00 = y00 ^ x10  ... x[i] = y[i] ^ x[i + shift] (for i < n - shift)
# → x[i] = y[i]                (for i >= n - shift)
#   x[i] = y[i] ^ x[i + shift] (for i < n - shift)
def undo_rshift(y: int, shift: int) -> int:
    n = 32
    x = 0
    for i in reversed(range(n)):
        if i >= n - shift:
            x |= (y & (1 << i))
        else:
            x |= ((y ^ (x >> shift)) & (1 << i))
    return x

# y = x ^ (x << 7) & 10011101001011000101011010000000b
#      x31 x30 x29 x28 x27 x26 x25 x24 x23 x22 x21 x20 x19 x18 x17 x16 x15 x14 x13 x12 x11 x10 x09 x08 x07 x06 x05 x04 x03 x02 x01 x00
# xor) x24         x21 x20 x19     x17         x14     x12 x11             x07     x05     x03 x02     x00
#      y31 y30 y29 y28 y27 y26 y25 y24 y23 y22 y21 y20 y19 y18 y17 y16 y15 y14 y13 y12 y11 y10 y09 y08 y07 y06 y05 y04 y03 y02 y01 y00

def undo_lshift_mask(y: int, shift: int, mask: int) -> int:
    n = 32
    x = 0
    for i in range(n):
        if i < shift:
            x |= (y & (1 << i))
        else:
            x |= ((y ^ ((x << shift) & mask)) & (1 << i))
    return x

def untemper(y: int) -> int:
    y = undo_rshift(y, 18)
    y = undo_lshift_mask(y, 15, 0xefc60000)
    y = undo_lshift_mask(y, 7, 0x9d2c5680)
    y = undo_rshift(y, 11)
    return y