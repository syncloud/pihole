#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=${1:?usage: build.sh <version>}

${DIR}/../apt.sh wget

BUILD_DIR=${DIR}/../build/snap/web/admin
mkdir -p ${BUILD_DIR}

cd ${DIR}/../build
${DIR}/../download-retry.sh https://github.com/pi-hole/web/archive/v${VERSION}.tar.gz v${VERSION}.tar.gz
tar xf v${VERSION}.tar.gz
cp -r web-${VERSION}/. ${BUILD_DIR}/
