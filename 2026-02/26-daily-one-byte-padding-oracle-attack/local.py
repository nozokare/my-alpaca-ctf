from Crypto.Util.Padding import pad, unpad
import Crypto.Cipher.AES as AES
import secrets

FLAG = "Alpaca{dummy}"
key = secrets.token_bytes(16)

def encrypt(plaintext):
    cipher = AES.new(key=key, mode=AES.MODE_CBC)
    encrypted_flag = cipher.encrypt(pad(plaintext.encode(), 16))
    return cipher.iv + encrypted_flag


def decrypt(iv, ciphertext):
    cipher = AES.new(key=key, mode=AES.MODE_CBC, iv=iv)
    a = cipher.decrypt(ciphertext)
    # print("[debug]", a[-16:], file=sys.stderr) # for debug. this is not respond to client. Let's look this output in your environment.
    try:
        unpad(a, 16)
        return True
    except:
        return False


plaintext = ""
for c in FLAG:
    plaintext += "?" * 15 + c

iv_ciphertext = encrypt(plaintext)
