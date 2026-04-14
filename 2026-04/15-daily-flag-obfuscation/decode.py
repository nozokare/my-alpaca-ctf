import ipaddress

chunks = []
with open("handout/data.h") as f:
    f.readline()
    while (line := f.readline()).startswith('"'):
        addr = ipaddress.IPv6Address(line.strip()[1:-2])
        chunks.append(addr.packed)

with open("handout/chal", "wb") as f:
    for chunk in chunks:
        f.write(chunk)
