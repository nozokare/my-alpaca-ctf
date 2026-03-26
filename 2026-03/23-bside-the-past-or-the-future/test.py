import numpy as np
import galois
from mt19937 import N, twist, states_to_bits, get_transition_matrix, untwist

A = get_transition_matrix()
print("shape:", A.shape)  # shape: (19968, 19968)

state = np.random.randint(0, 0xFFFF_FFFF, size=N, dtype=np.uint32)
state_next = twist(state)

s = galois.GF2(states_to_bits(state))
s_next = galois.GF2(states_to_bits(state_next))

print("is A @ s == s_next?:", np.all(A @ s == s_next))  # is A @ s == s_next?: True
print("is A[:, :31] == 0?:", np.all(A[:, :31] == 0))  # is A[:, :31] == 0?: True

state_recovered = untwist(state_next)

if np.all(state[1:] == state_recovered[1:]):
    print("recovered!")
else:
    print("recovery failed...")
