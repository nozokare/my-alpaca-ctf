from ast import literal_eval
from decimal import Decimal, getcontext
from pathlib import Path
import re
from typing import List

from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
from hashlib import sha256

import fpylll

getcontext().prec = 200

IWASHI_NUM = 100
IWASHI_WEIGHT_PRECISION = 180
IWASHI_PREYED_PROB = 0.5


def main():
    iwashi_weight, survived_iwashi_weight_sum, encrypted_flag = read_data(
        Path(__file__).parent / ".src" / "iwashi" / "output.txt"
    )

    # 10^180倍して整数にする
    to_int_scale = Decimal(10) ** IWASHI_WEIGHT_PRECISION
    weights = [int(w * to_int_scale) for w in iwashi_weight]
    target = int(survived_iwashi_weight_sum * to_int_scale)
    print(f"target = {target}")

    solution = solve_subset_sum_lll(weights, target)

    if solution is None:
        print("No solution found")
        return

    key = "".join("0" if survived else "1" for survived in solution)
    print(f"key = {key}")
    print(f"sum = {sum(w for w, survived in zip(weights, solution) if survived)}")
    print(f"flag = {decrypt(encrypted_flag, key)}")


def read_data(filepath: Path):
    with open(filepath) as f:
        lines = f.readlines()
        return (
            [Decimal(m) for m in re.findall(r"Decimal\('([^']+)'\)", lines[0])],
            Decimal(re.search(r"Decimal\('([^']+)'\)", lines[1]).group(1)),
            literal_eval(re.search(r"b'.+'", lines[2]).group(0)),
        )


def solve_subset_sum_lll(a: List[int], target: int, N=1) -> List[int]:
    """sum(a[j] * x[j] for j in range(n)) == target となるような x[j] ∈ {0, 1} を LLL アルゴリズムで探す。"""
    
    n = len(a)

    # 基底Bを以下のように構築する。(CLOS’91の埋込み)
    # B = [[2, 0, 0, ..., 0, a[0] * scale],
    #      [0, 2, 0, ..., 0, a[1] * scale],
    #      [0, 0, 2, ..., 0, a[2] * scale],
    #      ...
    #      [0, 0, 0, ..., 2, a[n-1] * scale],
    #      [1, 1, 1, ..., 1, target * scale]]

    B = fpylll.IntegerMatrix(n + 1, n + 1)
    for i in range(n):
        B[i, i] = 2
        B[i, n] = a[i] * N

    for j in range(n):
        B[n, j] = 1
    B[n, n] = target * N

    # Lenstra-Lenstra-Lovász (LLL) アルゴリズムを用いて基底Bを還元すると、
    # 生成する格子が同じで、短い基底ベクトルを含む基底B'が得られる。
    fpylll.LLL.reduction(B)

    # v = (±1, ±1, ..., ±1, 0) の形のベクトルが見つかれば、これが解を表す。
    for i in range(n + 1):
        v = list(B[i])
        if v[-1] == 0 and all(abs(vj) == 1 for vj in v[:-1]):
            # 格子の対称性により、v と -v の両方が解の候補になる。
            # v が正解の場合: x[j]=1 ⇔ v[j]=1, x[j]=0 ⇔ v[j]=-1
            x_pos = [(vj + 1) // 2 for vj in v[:-1]]
            if sum(xj * aj for xj, aj in zip(x_pos, a)) == target:
                return x_pos

            # -v が正解の場合: x[j]=1 ⇔ v[j]=-1, x[j]=0 ⇔ v[j]=1
            x_neg = [(-vj + 1) // 2 for vj in v[:-1]]
            if sum(xj * aj for xj, aj in zip(x_neg, a)) == target:
                return x_neg


def decrypt(ciphertext, key):
    iv = ciphertext[: AES.block_size]
    cipher = AES.new(sha256(key.encode()).digest(), AES.MODE_CBC, iv)
    plaintext = unpad(cipher.decrypt(ciphertext[AES.block_size :]), AES.block_size)
    return plaintext.decode()


if __name__ == "__main__":
    main()
