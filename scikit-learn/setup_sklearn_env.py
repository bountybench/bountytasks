import os
import subprocess
import sys

# Define paths
REPO_DIR = os.path.abspath(os.path.dirname(__file__))  # Root of scikit-learn repo
CODEBASE_DIR = os.path.join(REPO_DIR, "codebase")
BUILD_DIR = os.path.join(CODEBASE_DIR, "build")
PYTHON = sys.executable  # Get current Python executable

# Set the desired version of scikit-learn (e.g., "1.4.0", "1.3.0", etc.)
SCIKIT_LEARN_VERSION = "1.4.1.post1"

# Step 1: Checkout specific version
def checkout_version():
    print(f"[INFO] Checking out Scikit-Learn version {SCIKIT_LEARN_VERSION}...")
    
    try:
        subprocess.run(["git", "fetch", "--tags"], cwd=CODEBASE_DIR, check=True)
        subprocess.run(["git", "checkout", f"tags/{SCIKIT_LEARN_VERSION}", "-b", f"branch_{SCIKIT_LEARN_VERSION}"], cwd=CODEBASE_DIR, check=True)
        print(f"[SUCCESS] Checked out Scikit-Learn {SCIKIT_LEARN_VERSION}")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Failed to checkout {SCIKIT_LEARN_VERSION}: {e}")
        sys.exit(1)

# Step 2: Install dependencies
def install_dependencies():
    print("[INFO] Installing required dependencies...")
    deps = [
        "numpy",
        "scipy",
        "cython",
        "meson-python",
        "pytest",
        "joblib",
        "threadpoolctl",
        "setuptools",
        "wheel",
        "ninja"
    ]
    subprocess.run([PYTHON, "-m", "pip", "install", "--upgrade"] + deps, check=True)

# Step 3: Build Scikit-Learn from source
def build_sklearn():
    print("[INFO] Setting up and compiling Scikit-Learn...")

    # Ensure build directory exists
    if not os.path.exists(BUILD_DIR):
        os.makedirs(BUILD_DIR)

    # Run Meson build
    try:
        subprocess.run(["meson-python", "setup", "build"], cwd=CODEBASE_DIR, check=True)
        subprocess.run(["meson-python", "compile", "-C", "build"], cwd=CODEBASE_DIR, check=True)
        print("[SUCCESS] Build completed!")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Meson build failed: {e}")
        sys.exit(1)

# Step 4: Verify the build
def verify_build():
    print("[INFO] Verifying build...")

    # Ensure PYTHONPATH includes the local build
    new_pythonpath = f"{BUILD_DIR}:{os.environ.get('PYTHONPATH', '')}"
    os.environ["PYTHONPATH"] = new_pythonpath

    try:
        subprocess.run(
            [PYTHON, "-c", "import sklearn; sklearn.__check_build"],
            check=True,
            env=os.environ
        )
        print("[SUCCESS] Scikit-Learn build is verified!")
    except subprocess.CalledProcessError:
        print("[ERROR] Build verification failed. Scikit-Learn may not be installed correctly.")
        sys.exit(1)

if __name__ == "__main__":
    checkout_version()
    install_dependencies()
    build_sklearn()
    verify_build()
