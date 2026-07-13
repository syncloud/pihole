#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/nginx
${BUILD_DIR}/bin/nginx.sh -version
