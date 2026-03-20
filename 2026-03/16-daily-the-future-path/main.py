from os.path import join, dirname
from dotenv import dotenv_values
import random

from untemper import untemper
from session import NCSession

config = dotenv_values(join(dirname(__file__), ".env"))


class ThisSession(NCSession):
    def __init__(self, nc_string: str) -> None:
        super().__init__(nc_string)
        print(self.read().group(0))  # initial message

    def getPresent(self) -> int:
        self.write(f"1\n")
        match = self.read(r"\[present #(\d+)\] (\d+)\n> ")
        print(match.group(0))  # present message
        return int(match.group(2), 10)

    def startChallenge(self) -> int:
        self.write(f"2\n")
        match = self.read(r".* i = (\d+)")
        print(match.group(0))  # challenge message
        return int(match.group(1), 10)

    def answerChallenge(self, answer: int) -> None:
        self.write(f"{answer}\n")
        print(self.read().group(0))  # challenge response

    def leave(self) -> None:
        self.write(f"3\n")
        print(self.read().group(0))  # goodbye message


# Main logic

session = ThisSession(config["CONNECT"])

state_size = 624
states = []

for _ in range(state_size):
    present = session.getPresent()
    states.append(untemper(present))

i = session.startChallenge()

rng = random.Random()
rng.setstate((3, tuple(states + [state_size]), None))

for _ in range(i):
    future = rng.getrandbits(32)
future = rng.getrandbits(32)

print(f"Predicted future: {future}")
session.answerChallenge(future)

session.end()
