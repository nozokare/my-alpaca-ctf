import random
import secrets
from mt19937 import N, twist, untwist, temper, untemper


rng = random.Random(secrets.randbits(64))
values1 = [rng.getrandbits(32) for _ in range(N)]
values2 = [rng.getrandbits(32) for _ in range(N)]

state2 = [untemper(val) for val in values2]
state1 = untwist(state2)
state0 = untwist(state1)
state1_ = twist(state0)
assert values1[0] == temper(state1_[0])
