import galois
import numpy as np
from numba import jit
from typing import TypeAlias

UInt32Array: TypeAlias = np.ndarray[np.uint32]
BitArray: TypeAlias = np.ndarray[np.uint8]

N = 624
M = 397
UPPER_MASK = np.uint32(0x80000000)
LOWER_MASK = np.uint32(0x7FFFFFFF)
mag01 = np.array([0, 0x9908B0DF], dtype=np.uint32)


@jit
def twist(state: UInt32Array) -> UInt32Array:
    mt = state.copy()
    for kk in range(N - M):
        y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
        mt[kk] = mt[kk + M] ^ (y >> 1) ^ mag01[y & 1]

    for kk in range(N - M, N - 1):
        y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
        mt[kk] = mt[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 1]

    y = (mt[N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK)
    mt[N - 1] = mt[M - 1] ^ (y >> 1) ^ mag01[y & 1]

    return mt


@jit
# np.unpackbits(state.view(np.uint8), bitorder="little")
def states_to_bits(states: UInt32Array) -> BitArray:
    s = np.zeros(N * 32, dtype=np.uint8)
    for w in range(N):
        for j in range(32):
            s[w * 32 + j] = (states[w] >> j) & 1
    return s


@jit
# np.packbits(s, bitorder="little").view(np.uint32)
def bits_to_states(s: BitArray) -> UInt32Array:
    states = np.zeros(N, dtype=np.uint32)
    for w in range(N):
        for b in range(32):
            states[w] |= s[w * 32 + b] << b
    return states


@jit
# i 番目のビットだけが 1 の基底ベクトルを twist に通す
def map_base(i: int) -> BitArray:
    state = np.zeros(N, dtype=np.uint32)
    state[i // 32] = 1 << (i % 32)
    state_next = twist(state)
    return states_to_bits(state_next)


def build_transition_matrix() -> galois.GF2:
    A_cols = [map_base(i) for i in range(N * 32)]
    A = np.stack(A_cols, axis=1)
    return galois.GF2(A)


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


def untwist(s_next: UInt32Array) -> UInt32Array:
    A19937_inv = get_inverse_transition_matrix()
    s_next_19937 = galois.GF2(states_to_bits(s_next))[31:]
    s_19937 = A19937_inv @ s_next_19937
    s = np.concatenate((np.zeros(31), s_19937)) == 1
    return bits_to_states(s)


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
