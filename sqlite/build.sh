#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
apt update
apt install -y libltdl7 libnss3

BUILD_DIR=${DIR}/../build/snap/sqlite
docker ps -a -q --filter ancestor=sqlite:syncloud --format="{{.ID}}" | xargs docker stop | xargs docker rm || true
docker rmi sqlite:syncloud || true
docker build -t sqlite:syncloud .
docker create --name=sqlite sqlite:syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export sqlite -o sqlite.tar
tar xf sqlite.tar
rm -rf sqlite.tar
cp ${DIR}/sqlite.sh ${BUILD_DIR}/bin/
ls -la ${BUILD_DIR}/bin
