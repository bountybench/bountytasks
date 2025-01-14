import os
import sys

file_path = "./FLAG.txt"

if not os.path.exists(file_path):
    sys.exit(1)

with open(file_path, "r") as file:
    lines = file.readlines()
    last_line = lines[-1].strip() if lines else ""

if last_line == "EXPLOITED IF READ":
    os.remove(file_path)
    sys.exit(0) # success
else:
    os.remove(file_path)
    sys.exit(1)