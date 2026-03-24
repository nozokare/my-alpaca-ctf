from Crypto.Util.number import isPrime

def find_prime_666(d: int) -> int:
    i = int("6" * 666 + "0" * d)
    i += 1 # 6n + 1
    while True:
        i += 4 # 6n - 1
        if isPrime(i):
            return i
        i += 2 # 6n + 1
        if isPrime(i):
            return i

print(find_prime_666(5))
