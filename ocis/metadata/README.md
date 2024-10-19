# Building OCiS

## Build issue documentation

This file lists the methods that have been attempted to resolve build issues
with the ocis application.

Commit 526ae6c is the most recent one that passes the exploit tests. However,
this commit uses an owncloud docker image rather than one built locally.

The `Dockerfile` in the repo suggests two paths to building the application.
The method that is currently being used is to run `make -C ocis dev-docker` and
then use that image to run the application. This will successfully build the
application. It will run locally (on WSL2 in Windows 11 on x86_64) and the
exploit tests will pass but in CI, the application server will start and the
application will immediately crash. The logs indicate that this is because
there is no `identifier/index.html` file, however, neither the file nor the
directory appear to exist in the image when the application is run locally.

The other approach to building the application is using
`docker build -t owncloud/ocis:custom .`. This has not been successfully run
locally or in CI. Here are the changes that can be made to get further through
the build process (although it will not finish):

* Remove `--openssl-legacy-provider` from the `build` field in `remote_files/services/idp/package.json` (this is already done).
* run `git init` locally inside `remote_files` or modify the `start_docker.sh` script to initialize a git repo before attempting to build
* add `mkdir assets` after `git clean -xfd assets` inside `remote_files/services/web/Makefile`.

After doing these things, `make` will now fail without giving an error message
on `RUN make ci-go-generate build` inside `Dockerfile`.

## Additional stuff

In order to run the application, you need to run the following commands (this
has already been done in this commit).

```bash
mkdir -p $PWD/ocis/ocis-config
mkdir -p $PWD/ocis/ocis-data

sudo chown -Rfv 1000:1000 $PWD/ocis/

docker run --rm -it \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    owncloud/ocis init

# The response here can be either yes or no

docker run \
    --name ocis_runtime \
    --rm \
    -it \
    -p 9200:9200 \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    --mount type=bind,source=$PWD/ocis/ocis-data,target=/var/lib/ocis \
    -e OCIS_INSECURE=true \
    -e PROXY_HTTP_ADDR=0.0.0.0:9200 \
    -e OCIS_URL=https://<your-hostname>:9200 \
    owncloud/ocis
# <your-hostname> should be replaced with ocis-app in CI or localhost locally.
```
