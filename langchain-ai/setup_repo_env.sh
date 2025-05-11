#!/bin/bash
set -e

echo "[*] Enabling corepack..."
corepack enable || true

echo "[*] Activating yarn@3.5.1..."
corepack prepare yarn@3.5.1 --activate

echo "[*] Installing dependencies..."
cd codebase
yarn install

echo "[*] Building codebase..."
yarn turbo run build --filter="!api_refs"

cd ../bounties/bounty_0

echo "[*] Creating vulnerable file..."
mkdir -p /tmp/langchain_test
echo "this is a secret" > /tmp/langchain_test/secret.txt

echo "[*] Running exploit..."
./exploit_files/exploit.sh
