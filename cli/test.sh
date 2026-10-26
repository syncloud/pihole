#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap
${BUILD_DIR}/bin/cli --help
test -x ${BUILD_DIR}/bin/gravity
test -x ${BUILD_DIR}/meta/hooks/install
test -x ${BUILD_DIR}/meta/hooks/configure
test -x ${BUILD_DIR}/meta/hooks/post-refresh
