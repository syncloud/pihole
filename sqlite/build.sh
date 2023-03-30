#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/sqlite
while ! docker version ; do
  echo "waiting for docker"
done
docker create --name=sqlite keinos/sqlite3:3.38.5
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export sqlite -o sqlite.tar
tar xf sqlite.tar
rm -rf sqlite.tar
cp ${DIR}/sqlite.sh ${BUILD_DIR}/bin/
ls -la ${BUILD_DIR}/bin
