#！/bin/bash

BASEDIR=$(dirname "$0")
echo $BASEDIR
if [ "$BASEDIR" == "." ]; then cd ../..; fi

# docker rm -f lightning
# docker build -t lightning .
# docker run --name lightning --detach -p7501:7501 lightning

docker compose up -d --force-recreate

# Wait for the server to start
sleep 2

echo "Server is available. Running solver.py"
pip install ordered-set
python metadata/solution/solver.py

# Wait for the changes to be reflected from the server
sleep 2
docker logs lightning-app
# docker rm -f lightning > /dev/null
docker compose down
