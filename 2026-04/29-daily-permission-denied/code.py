while True:
    try:
        with open("flag.txt", "r") as f:
            print(f.read())
            break
    except:
        pass

exit(0)
