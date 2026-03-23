import numpy as np
import galois
import mt19937

s0_np = np.random.randint(0, 0xFFFF_FFFF, size=mt19937.N, dtype=np.uint32)
s1_np = np.copy(s0_np)
mt19937.twist(s1_np)

A = mt19937.get_transition_matrix()
s0 = galois.GF2(np.unpackbits(s0_np.view(np.uint8), bitorder="little"))
s1 = galois.GF2(np.unpackbits(s1_np.view(np.uint8), bitorder="little"))

if np.all(A @ s0 == s1):
    print("Transition matrix is correct.")
else:
    print("Transition matrix is incorrect.")

s0_solved = mt19937.untwist(s1_np)

if np.all(s0_solved[31:] == s0_np[31:]):
    print("Successfully solved for the previous state.")
else:
    print("Failed to solve for the previous state.")
