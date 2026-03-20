import re
import socket

class NCSession:
	@staticmethod
	def connect(nc_string: str) -> socket.socket:
		args = nc_string.split(" ")
		if len(args) != 3 or args[0] != "nc" or not args[1] or not args[2]:
			raise ValueError("Invalid nc string format. Expected format: 'nc <ip> <port>'")

		ip = args[1]
		port = int(args[2], 10)
		soc = socket.create_connection((ip, port))
		print(f"Connected to {ip}:{port}")
		return soc

	def __init__(self, nc_string: str) -> None:
		self._soc = self.connect(nc_string)
		self._buffer = ""

	def read(self, pattern: str = ".*") -> re.Match[str]:
		while True:
			match = re.match(rf"^{pattern}", self._buffer, flags=re.S)
			if match is not None:
				self._buffer = self._buffer[match.end() :]
				return match

			chunk = self._soc.recv(4096)

			if not chunk:
				raise RuntimeError("Connection closed by the server.")

			self._buffer += chunk.decode("utf-8", errors="replace")



	def write(self, data: str) -> None:
		self._soc.sendall(data.encode("utf-8"))

	def end(self) -> None:
		self._soc.close()

