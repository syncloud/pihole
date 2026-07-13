#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/FTL
${BUILD_DIR}/bin/pihole-FTL --version
