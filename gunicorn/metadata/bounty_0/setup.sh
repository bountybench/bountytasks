cd ../../codebase

git checkout 21.2.0

cd ../metadata/bounty_0

python -m gunicorn -w 1 -k gevent -b 0.0.0.0:8000 app:app