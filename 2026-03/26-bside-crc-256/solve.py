import os
import dotenv

dotenv.load_dotenv()
nc, host, port = os.getenv("CONNECT").split(" ")
assert nc == "nc" and host and port.isnumeric(), "invalid CONNECT string"

from crc import gf2mod, crc, G32, G256
from galois import GF2
import numpy as np
from pwn import remote


def is_linearly_independent(vectors):
    matrix = GF2(np.stack(vectors, axis=1))
    return np.linalg.matrix_rank(matrix) == len(vectors)


def search_matrix(G: int):
    k = G.bit_length() - 1
    # 自由度が足りるまで m1 = "A" * L の長さを増やす
    for L in range(k // 4, k):
        l = L.bit_length() + (-L.bit_length() % 8)  # 付加される長さのビット数
        A_cols = []
        index = []
        for i in range(L * 8):
            # 自由度のないビットはスキップ
            if (1 << i % 8) & 0b1101_0001:
                continue

            # r_i を計算
            e_i = 1 << (k + l + i)
            r_i = gf2mod(e_i, G)
            r_i_vec = [(r_i >> j) & 1 for j in range(k)]

            # 線型独立な列が見つかったら追加
            if is_linearly_independent(A_cols + [r_i_vec]):
                A_cols.append(r_i_vec)
                index.append(i)

        if len(A_cols) == k:
            A = GF2(np.stack(A_cols, axis=1))
            return A, index, L

    raise ValueError("no solution found")


def solve(c0: int, G: int) -> bytes:
    k = G.bit_length() - 1
    A, index, L = search_matrix(G)
    print(f"A: A{A.shape}, L: {L}")

    m1 = "A" * L  # ベースとなるメッセージ
    c1 = crc(m1.encode(), G)  # ベースとなるCRC値

    target = GF2([(c1 ^ c0) >> i & 1 for i in range(k)])
    x = np.linalg.solve(A, target)
    m1_int = int.from_bytes(m1.encode(), "big")
    for i, flip in zip(index, x):
        if flip:
            m1_int ^= 1 << i
    return m1_int.to_bytes(L, "big")


def challenge(conn: remote, g: int):
    k = (g.bit_length() - 1) // 4
    conn.recvuntil(b"target sum: ")
    c0 = int(conn.recvline().strip(), 16)
    print(f"target sum: 0x{c0:0{k}X}")
    m1 = solve(c0, g)
    c1 = crc(m1, g)
    print(f"m1: {m1} c1: 0x{c1:0{k}X}")
    assert c1 == c0, f"c1: 0x{c1:0{k}X} != c0: 0x{c0:0{k}X}"
    conn.sendline(m1)


conn = remote(host, int(port))
challenge(conn, G32)
challenge(conn, G256)
conn.interactive()
