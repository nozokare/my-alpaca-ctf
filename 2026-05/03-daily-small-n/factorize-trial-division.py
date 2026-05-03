with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])

import time

start = time.time()

for q in range(2**31 + 1, 2**32, 2):
    if n % q == 0:
        print(f"found {q} in {time.time() - start:.2f} sec")
        exit(0)

print("failed")
