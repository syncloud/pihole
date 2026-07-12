#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/bind9
while ! docker version >/dev/null 2>&1 ; do
  echo "waiting for docker"
  sleep 1
done
docker build -t bind9 .
docker create --name=bind9 bind9

mkdir -p ${DIR}/build
cd ${DIR}/build
docker export bind9 -o app.tar
tar xf app.tar
rm -rf app.tar

mkdir -p ${BUILD_DIR}/bin
cp -r usr ${BUILD_DIR}
cp -r lib ${BUILD_DIR}
cp -r ${DIR}/bin/* ${BUILD_DIR}/bin
${BUILD_DIR}/bin/dig.sh -v
