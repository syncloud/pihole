#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
SPEC=$1
DISTRO=$2
ARCH=$3
NAME=pihole
DOMAIN="${DISTRO}.com"
APP_DOMAIN="${NAME}.${DOMAIN}"

getent hosts $APP_DOMAIN | sed "s/$APP_DOMAIN/auth.$DOMAIN/g" | tee -a /etc/hosts
APP_ARCHIVE_PATH=$(realpath $(cat ${DIR}/package.name))
cd ${DIR}/test
./deps.sh
py.test -x -s ${SPEC} --distro=$DISTRO --domain=$DOMAIN --app-archive-path=$APP_ARCHIVE_PATH --device-host=$APP_DOMAIN --app=$NAME --arch=$ARCH
