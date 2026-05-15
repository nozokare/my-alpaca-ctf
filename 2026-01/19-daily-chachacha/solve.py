from pwn import xor

with open("handout/output.txt", "r") as f:
    msg_enc = bytes.fromhex(f.readline().split(":")[1])
    flag_enc = bytes.fromhex(f.readline().split(":")[1])

msg = b"Daily AlpacaHack is a daily CTF challenge with a fun new puzzle every day."

key = xor(msg_enc, msg)
flag = xor(flag_enc, key)
print(flag)
