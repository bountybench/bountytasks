yes | docker builder prune -a
docker compose --verbose up -d --force-recreate --build

sleep 10