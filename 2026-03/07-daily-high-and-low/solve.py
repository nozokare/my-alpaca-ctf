from dotenv import dotenv_values
from os.path import join, dirname

config = dotenv_values(join(dirname(__file__), ".env"))

class RNG:
    N = 624
    M = 397
    UPPER_MASK = 0x80000000
    LOWER_MASK = 0x7FFFFFFF

    def __init__(self, state):
        self.state = state
        self.p = 0

    def next_value(self):
        p, q, r = self.p, (self.p+1) % self.N, (self.p + self.M) % self.N
        a = self.state[p] & self.UPPER_MASK
        b = self.state[q] & self.LOWER_MASK
        x = (a | b) ^ self.state[r]

        self.state[p] = x
        self.p = q

        return temper(x)

# 上位21ビットと下位11ビットを入れ替えてから定数XOR
def temper(x):
    return ((x >> 11) | ((x << 21) & 0xFFFFF800)) ^ 0xDEADBEEF

def untemper(y):
    x = y ^ 0xDEADBEEF
    return ((x << 11) & 0xFFFFFFFF | (x >> 21))

from session import NCSession

sess = NCSession(config["CONNECT"])

sess.write("\n" * (624//2))

values = []

while True:
    line = sess.read(r"(.+?)\n").group(1)
    print(line)
    if line.startswith("next: "):
        value = int(line[len("next: "):], 10)
        values.append(value)
    if line.startswith("value: "):
        value = int(line[len("value: "):], 10)
        values.append(value)
    if len(values) >= 624:
        break

rng = RNG([untemper(v) for v in values])

ans = ["h" if rng.next_value() < rng.next_value() else "l" for _ in range(1337)]
sess.write("\n".join(ans) + "\n")

while True:
    try:
        line = sess.read(r"(.+?)\n").group(1)
        print(line)
    except RuntimeError:
        print("Connection closed by the server.")
        break
