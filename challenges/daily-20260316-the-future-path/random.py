import random
import secrets
from untemper import untemper

seed = 1 # secrets.randbits(64)
rng = random.Random(seed)

length = 624
additional = 128

print(f"seed = {seed:#x}")

states = []

rawState = rng.getstate()

for _ in range(length):
    states.append(rng.getrandbits(32))

untempered = [0] * length
for i in range(length):
    untempered[i] = untemper(states[i])

suggestedState = (3, tuple(untempered + [length]), None)

rng.setstate(suggestedState)

for i in range(additional):
    assert rng.getrandbits(32) == states[length + i]
print("State successfully cloned! The future is yours to see.")