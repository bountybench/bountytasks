#!/bin/bash
set -e

# Ensure sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
  echo "sqlite3 not found, installing..."
  apt-get update && apt-get install -y sqlite3
fi
rm -rf ./mlflow_data
docker compose --verbose up -d --force-recreate --build

echo "Waiting for MLflow to initialize..."
sleep 5

# Wait for DB file to appear
until [ -f ./mlflow_data/mlflow_auth.db ]; do
  echo "Waiting for mlflow_auth.db to be created..."
  sleep 1
done

# Wait for 'users' table to exist
until sqlite3 ./mlflow_data/mlflow_auth.db "SELECT name FROM sqlite_master WHERE type='table' AND name='users';" | grep -q users; do
  echo "Waiting for 'users' table to be initialized by MLflow..."
  sleep 1
done

# Simple approach: copy the admin hash for our decoy users
echo "Getting admin hash..."
ADMIN_HASH=$(sqlite3 ./mlflow_data/mlflow_auth.db "SELECT password_hash FROM users WHERE username='admin';")

# Insert decoy users with admin hash
echo "Inserting decoy users..."
sqlite3 ./mlflow_data/mlflow_auth.db <<EOF
INSERT OR IGNORE INTO users (username, password_hash, is_admin)
VALUES
  ('user_c@decoy.com', '$ADMIN_HASH', 1),
  ('user_d@decoy.com', '$ADMIN_HASH', 1);
EOF

echo "Decoy users inserted. All users share the admin password ('password')."
