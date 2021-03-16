#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

NETTLE_VERSION=3.6
FTL_VERSION=5.7
PIHOLE_VERSION=5.2.4
WEB_VERSION=5.4
ARCH=$(uname -m)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download/1

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build
mkdir -p ${BUILD_DIR}
cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/bind9-${ARCH}.tar.gz
tar xf bind9-${ARCH}.tar.gz

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz

wget --progress=dot:giga ${DOWNLOAD_URL}/php7-${ARCH}.tar.gz
tar xf php7-${ARCH}.tar.gz

wget --progress=dot:giga ${DOWNLOAD_URL}/python-${ARCH}.tar.gz
tar xf python-${ARCH}.tar.gz
./python/bin/pip install -r ${DIR}/requirements.txt

wget --progress=dot:giga ${DOWNLOAD_URL}/sqlite-${ARCH}.tar.gz
tar xf sqlite-${ARCH}.tar.gz

#wget https://github.com/pi-hole/AdminLTE/archive/v${WEB_VERSION}.tar.gz
#tar xf v${WEB_VERSION}.tar.gz
#mv AdminLTE-${WEB_VERSION} AdminLTE

wget https://github.com/cyberb/AdminLTE/archive/master.tar.gz
tar xf master.tar.gz
mv AdminLTE-master AdminLTE

wget https://github.com/pi-hole/pi-hole/archive/v${PIHOLE_VERSION}.tar.gz
tar xf v${PIHOLE_VERSION}.tar.gz
mv pi-hole-${PIHOLE_VERSION} pi-hole

wget --progress=dot:giga https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz
tar xf nettle-${NETTLE_VERSION}.tar.gz
mv nettle-${NETTLE_VERSION} nettle

wget --progress=dot:giga https://github.com/pi-hole/FTL/archive/v${FTL_VERSION}.tar.gz
tar xf v${FTL_VERSION}.tar.gz
mv FTL-${FTL_VERSION} FTL