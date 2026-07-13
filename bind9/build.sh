#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/bind9

apt-get update
apt-get install -y dnsutils

mkdir -p ${BUILD_DIR}/bin
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r ${DIR}/bin/* ${BUILD_DIR}/bin
${BUILD_DIR}/bin/dig.sh -v
