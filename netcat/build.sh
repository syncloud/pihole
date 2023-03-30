#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/netcat
while ! docker version ; do
  echo "waiting for docker"
  sleep 1
done
docker build -t netcat .
docker create --name=netcat netcat

mkdir $DIR/build
cd $DIR/build
docker export netcat -o app.tar
tar xf app.tar
rm -rf app.tar

mkdir -p ${BUILD_DIR}
mkdir ${BUILD_DIR}/lib
cp $DIR/build/lib/*-linux*/ld-*.so ${BUILD_DIR}/lib/ld.so
cp $DIR/build/lib/*-linux*/libc.so* ${BUILD_DIR}/lib
mkdir ${BUILD_DIR}/bin
cp $DIR/build/bin/nc.traditional ${BUILD_DIR}/bin/nc
cp ${DIR}/nc.sh ${BUILD_DIR}/bin
${BUILD_DIR}/bin/nc.sh -h
