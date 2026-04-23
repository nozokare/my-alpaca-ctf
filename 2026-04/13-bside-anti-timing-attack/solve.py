import os

nc, host, port = os.getenv("CONNECT").split(" ")

import string
import socket


def try_flag(flag):
    with socket.create_connection((host, int(port))) as conn:
        try:
            conn.send(flag + b"\n")
            _ = conn.recv(6)  # "FLAG: "
            if not conn.recv(1):
                return "fin"
            else:
                return "correct"
        except ConnectionResetError:
            return "reset"


flag = "Alpaca{"
charset = "}_" + string.digits + string.ascii_letters

while not flag.endswith("}"):
    for c in charset:
        new_flag = flag + c
        print(f"{new_flag}: ", end="")
        result = try_flag(new_flag.encode())
        print(result)
        if result != "reset":
            flag = new_flag
            break
