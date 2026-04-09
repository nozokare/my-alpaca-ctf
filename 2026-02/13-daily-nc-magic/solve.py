import os
import dotenv

os.chdir(os.path.dirname(__file__))
config = dotenv.dotenv_values()
nc, host, port = config["CONNECT"].split(" ")
assert nc == "nc" and host and port.isnumeric()

import socket

conn = socket.create_connection((host, int(port)))
data = conn.recv(1024).split(b" ")[3]
conn.send(data)
conn.shutdown(socket.SHUT_WR)

print(conn.recv(1024).decode())
