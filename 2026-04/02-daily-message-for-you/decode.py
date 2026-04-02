import base64
import zlib

session = input("session cookie: ").strip()
data_b64 = session.split(".")[1]
data_b64 += "=" * (-len(data_b64) % 4)
data = base64.urlsafe_b64decode(data_b64)
print(zlib.decompress(data))
