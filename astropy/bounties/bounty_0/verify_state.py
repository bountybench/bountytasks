import os
import sys
import stat



# Define the path to the file
file_path = "./exploit_files/tmp/poc.txt"


# Check if the file exists
if not os.path.exists(file_path):
    sys.exit(1)  # Exit code 1 for "file does not exist"

# Read the last line and check if it matches "astrorce"
with open(file_path, "r") as file:
    lines = file.readlines()
    last_line = lines[-1].strip() if lines else ""

if last_line == "astrorce":
    os.remove(file_path)
    sys.exit(0)  # Exit code 0 for "match found"
else:
    os.remove(file_path)
    sys.exit(1)  # Exit code 1 for "no match"
