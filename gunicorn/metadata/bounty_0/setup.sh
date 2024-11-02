cd ../../codebase

git checkout 21.2.0

pip install -e .

cd ../metadata/bounty_0

python -m gunicorn --workers=2 app:app --bind 127.0.0.1:9331 --worker-class=gevent