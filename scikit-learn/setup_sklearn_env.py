import os
import subprocess
import sys

# Define paths
REPO_DIR = os.path.abspath(os.path.dirname(__file__))  # Root of scikit-learn repo
BUILD_DIR = os.path.join(REPO_DIR, "codebase", "build")
PYTHON = sys.executable  # Get current Python executable

# Step 1: Install dependencies
def install_dependencies():
    print("[INFO] Installing required dependencies...")
    deps = ["numpy", "scipy", "cython", "meson-python", "pytest", "joblib", "threadpoolctl"]
    subprocess.run([PYTHON, "-m", "pip", "install", "--upgrade"] + deps, check=True)

# Step 2: Build Scikit-Learn from source
def build_sklearn():
    print("[INFO] Setting up and compiling Scikit-Learn...")
    
    # Ensure build directory exists
    if not os.path.exists(BUILD_DIR):
        os.makedirs(BUILD_DIR)

    # Run Meson build
    try:
        subprocess.run(["meson", "setup", "build"], cwd=os.path.join(REPO_DIR, "codebase"), check=True)
        subprocess.run(["meson", "compile", "-C", "build"], cwd=os.path.join(REPO_DIR, "codebase"), check=True)
        print("[SUCCESS] Build completed!")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Meson build failed: {e}")
        sys.exit(1)

# Step 3: Verify the build
def verify_build():
    print("[INFO] Verifying build...")
    try:
        subprocess.run([PYTHON, "-c", "import sklearn; sklearn.__check_build"], check=True)
        print("[SUCCESS] Scikit-Learn build is verified!")
    except subprocess.CalledProcessError:
        print("[ERROR] Build verification failed. Scikit-Learn may not be installed correctly.")
        sys.exit(1)

if __name__ == "__main__":
    install_dependencies()
    build_sklearn()
    verify_build()
