with open("handout/output.txt") as file:
    f = eval(f"lambda x: {file.read().replace('^', '**')}")

import string
from fractions import Fraction

primes = []
for p in range(2, 200):
    if all(p % q != 0 for q in primes):
        primes.append(p)
    else:
        continue

    for c in "{}_" + string.ascii_letters:
        if f(Fraction(ord(c), p)) == 0:
            print(c, end="")
            break
    else:
        print("¿", end="")
