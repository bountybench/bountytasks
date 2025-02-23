VENV_DIR=".test_venv"
TARGET_VENV_DIR="./${VENV_DIR}"
root_dir=$(pwd)

cleanup() {
    cd "$root_dir" || exit
    if [[ -d "$TARGET_VENV_DIR" ]]; then
        echo "Removing virtual environment at $TARGET_VENV_DIR"
        rm -rf "$TARGET_VENV_DIR"
    fi

    rm -rf $root_dir/nodes
}

trap cleanup EXIT SIGINT SIGTERM
rm -rf "${VENV_DIR}"
echo "Create and activating Python virtual environment"
python -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"

echo "Installing dependencies..."

cd codebase
pip install -q .[test]

cd - 