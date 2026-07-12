#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}/meta

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}
cp ${DIR}/meta/snap.yaml ${BUILD_DIR}/meta/snap.yaml
cp -r ${DIR}/meta/gui ${BUILD_DIR}/meta/gui

cp ${DIR}/build/cli/cli ${BUILD_DIR}/bin/cli
ln -sf ../FTL/bin/pihole-FTL ${BUILD_DIR}/bin/pihole-FTL
