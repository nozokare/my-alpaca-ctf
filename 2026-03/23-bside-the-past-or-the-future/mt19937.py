import galois
import numpy as np
from numba import jit
from typing import TypeAlias

UInt32Array: TypeAlias = np.ndarray[np.uint32]

N = 624
M = 397
UPPER_MASK = np.uint32(0x80000000)
LOWER_MASK = np.uint32(0x7FFFFFFF)
mag01 = np.array([0, 0x9908B0DF], dtype=np.uint32)


@jit
def twist(mt: UInt32Array):
    for kk in range(N - M):
        y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
        mt[kk] = mt[kk + M] ^ (y >> 1) ^ mag01[y & 1]

    for kk in range(N - M, N - 1):
        y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
        mt[kk] = mt[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 1]

    y = (mt[N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK)
    mt[N - 1] = mt[M - 1] ^ (y >> 1) ^ mag01[y & 1]


@jit
def map_base(wi: int, bi: int) -> UInt32Array:
    mt = np.zeros(N, dtype=np.uint32)
    mt[wi] = 1 << bi
    twist(mt)
    return mt


def build_transition_matrix() -> galois.GF2:
    A_words = [map_base(wi, bi) for wi in range(N) for bi in range(32)]
    A_uint8 = np.array(A_words, dtype=np.uint32).view(np.uint8)
    A_bits = np.unpackbits(A_uint8, axis=1, bitorder="little")
    return galois.GF2(A_bits.T)


A = None  # Placeholder for the transition matrix
A19937_inv = None  # Placeholder for the inverse of transition matrix


def warmup():
    get_transition_matrix()
    get_inverse_transition_matrix()


def get_transition_matrix() -> galois.GF2:
    global A
    if A is None:
        A = build_transition_matrix()
    return A


def get_inverse_transition_matrix() -> galois.GF2:
    global A19937_inv
    if A19937_inv is None:
        A = get_transition_matrix()
        A19937_inv = np.linalg.inv(A[31:, 31:])
    return A19937_inv


def untwist(s1: UInt32Array) -> UInt32Array:
    A19937_inv = get_inverse_transition_matrix()
    s1_19937 = galois.GF2(np.unpackbits(s1.view(np.uint8), bitorder="little"))[31:]
    s0_19937 = A19937_inv @ s1_19937
    s0_bits = np.concat((np.zeros(31), s0_19937)) == 1
    return np.packbits(s0_bits, bitorder="little").view(np.uint32)


MASK1 = 0x9D2C5680
MASK2 = 0xEFC60000


def temper(s: int) -> int:
    s ^= s >> 11
    s ^= (s << 7) & MASK1
    s ^= (s << 15) & MASK2
    s ^= s >> 18
    return s


def undo_rshift(y: int, shift: int) -> int:
    n = 32
    x = 0
    for i in reversed(range(n)):
        if i >= n - shift:
            x |= y & (1 << i)
        else:
            x |= (y ^ (x >> shift)) & (1 << i)
    return x


def undo_lshift_mask(y: int, shift: int, mask: int) -> int:
    n = 32
    x = 0
    for i in range(n):
        if i < shift:
            x |= y & (1 << i)
        else:
            x |= (y ^ ((x << shift) & mask)) & (1 << i)
    return x


def untemper(y: int) -> int:
    y = undo_rshift(y, 18)
    y = undo_lshift_mask(y, 15, MASK2)
    y = undo_lshift_mask(y, 7, MASK1)
    y = undo_rshift(y, 11)
    return y
