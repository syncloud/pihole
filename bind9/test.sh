#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/bind9
${BUILD_DIR}/bin/dig.sh -v
