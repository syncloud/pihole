#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=6.6

apt-get update
apt-get install -y wget

BUILD_DIR=${DIR}/../build/snap/web/admin
mkdir -p ${BUILD_DIR}

cd ${DIR}/../build
wget --progress=dot:giga https://github.com/pi-hole/web/archive/v${VERSION}.tar.gz
tar xf v${VERSION}.tar.gz
cp -r web-${VERSION}/. ${BUILD_DIR}/
