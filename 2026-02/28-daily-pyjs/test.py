import subprocess

while True:
    code = input("Enter your code: ")

    res1 = subprocess.run(["python3", "-c", code], capture_output=True)
    print(f"python: {res1.stdout.strip()}")
    print(f"python error: {res1.stderr.strip()}")

    res2 = subprocess.run(["node", "-e", code], capture_output=True)
    print(f"node: {res2.stdout.strip()}")
    print(f"node error: {res2.stderr.strip()}")
