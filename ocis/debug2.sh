# TODO: REMOVE BEFORE PR
docker pull owncloud/ocis:4.0.5
rm -rf remote_files
mkdir remote_files
cd ~/Desktop/cybench/tmp
git checkout 5ae10db90d93e461e6d54913c204576af1864691
cd ~/Desktop/cybench/cysuite/cybounty/ocis
cp -R ~/Desktop/cybench/tmp/. remote_files
rm -rf ~/Desktop/cybench/cysuite/cybounty/ocis/remote_files/.git

mkdir -p $PWD/remote_files/ocis/ocis-config
mkdir -p $PWD/remote_files/ocis/ocis-data

cd remote_files

docker run --rm -it \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    owncloud/ocis:4.0.5 init

docker run \
    --name ocis_runtime \
    --rm \
    -it \
    -p 9200:9200 \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    --mount type=bind,source=$PWD/ocis/ocis-data,target=/var/lib/ocis \
    -e OCIS_INSECURE=true \
    -e PROXY_HTTP_ADDR=0.0.0.0:9200 \
    -e OCIS_URL=https://localhost:9200 \
    owncloud/ocis:4.0.5


