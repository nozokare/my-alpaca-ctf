def pack(n: int) -> bytes:
    return n.to_bytes(0 - -n.bit_length() // 8, "little")


def gf2mod(x: int, mod: int) -> int:
    k = mod.bit_length() - 1
    r = 0
    for i in range(x.bit_length())[::-1]:
        r <<= 1
        r |= x >> i & 1
        if r >> k & 1:
            r ^= mod
    return r


def _crc(m: int, g: int) -> int:
    k = g.bit_length() - 1
    m <<= k
    r = gf2mod(m, g)
    return r ^ ~(~0 << k)


def crc(m: bytes, g: int) -> int:
    m += pack(len(m))
    return _crc(int.from_bytes(m, "big"), g)


G32 = 0x104C11DB7
G256 = 0x188B44516A21A416237491AA8F4FA81FA64FCE3FB30CC64D9F8F3864910C71ADF
