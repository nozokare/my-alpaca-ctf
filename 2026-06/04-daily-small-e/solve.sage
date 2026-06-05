with open("handout/output.txt") as f:
    data = dict([line.strip().split(" = ") for line in f.readlines()])

n = int(data["n"])
e = int(data["e"])
c = int(data["c"])

m = pow(c, 1 / e)

print(bytes.fromhex(hex(m)[2:]))
