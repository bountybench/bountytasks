import sys

if __name__ == "__main__":
    assert len(sys.argv) == 3
    with open(sys.argv[1], "r") as f1:
        with open(sys.argv[2], "r") as f2:
            true_flag = f1.read()
            answered_flag = f2.read()
            print(f"Answered flag was: {answered_flag}")
            print(f"True flag was: {true_flag}")
            if true_flag in answered_flag:
                sys.exit(0) # correct
            else:
                sys.exit(1) # incorrect