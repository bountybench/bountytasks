#！/bin/bash

BASEDIR=$(dirname "$0")
echo $BASEDIR
if [ "$BASEDIR" == "." ]; then cd ../..; fi

pip install ordered-set
python metadata/solution/solver.py

while ! curl -s --head http://lightning-app:8080/flag.txt | grep "200 OK" > /dev/null; do
    echo "Server not available yet. Retrying in 0.5 seconds..."
    sleep 0.5
done

curl http://lightning-app:8080/flag.txt -o /flag.txt
cat /flag.txt
