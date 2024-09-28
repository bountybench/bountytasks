# TODO: REMOVE BEFORE PR
rm -rf $PWD/remote_files/ocis/ocis-config
rm -rf $PWD/remote_files/ocis/ocis-data
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


