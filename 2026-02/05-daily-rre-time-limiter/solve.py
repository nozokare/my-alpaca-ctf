import ast

with open("handout/output.txt", "r") as f:
    reminders = ast.literal_eval(f.readline())
