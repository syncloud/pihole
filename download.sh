#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

FTL_VERSION=v6.7
PIHOLE_VERSION=6.4.3
WEB_VERSION=6.6
ARCH=$(uname -m)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download

case ${ARCH} in
  x86_64)  FTL_ARCH=amd64 ;;
  aarch64) FTL_ARCH=arm64 ;;
  armv7l)  FTL_ARCH=armv7 ;;
  armv6l)  FTL_ARCH=armv6 ;;
  *) echo "unsupported arch: ${ARCH}"; exit 1 ;;
esac

apt update
apt -y install wget

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR
cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/bind9/bind9-${ARCH}.tar.gz
tar xf bind9-${ARCH}.tar.gz

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz

#wget --progress=dot:giga ${DOWNLOAD_URL}/1/sqlite-${ARCH}.tar.gz
#tar xf sqlite-${ARCH}.tar.gz

#wget https://github.com/pi-hole/AdminLTE/archive/v${WEB_VERSION}.tar.gz
#tar xf v${WEB_VERSION}.tar.gz
#mv AdminLTE-${WEB_VERSION} AdminLTE

wget https://github.com/pi-hole/web/archive/v${WEB_VERSION}.tar.gz
tar xf v${WEB_VERSION}.tar.gz
mv web-${WEB_VERSION} AdminLTE

wget https://github.com/pi-hole/pi-hole/archive/v${PIHOLE_VERSION}.tar.gz
tar xf v${PIHOLE_VERSION}.tar.gz
mv pi-hole-${PIHOLE_VERSION} pi-hole

FTL_URL=https://github.com/pi-hole/FTL/releases/download/${FTL_VERSION}
mkdir -p ${DIR}/build/FTL/bin
wget --progress=dot:giga -O pihole-FTL ${FTL_URL}/pihole-FTL-${FTL_ARCH}
wget --progress=dot:giga -O pihole-FTL.sha1 ${FTL_URL}/pihole-FTL-${FTL_ARCH}.sha1
echo "$(cut -d' ' -f1 pihole-FTL.sha1)  pihole-FTL" | sha1sum -c -
chmod +x pihole-FTL
mv pihole-FTL ${DIR}/build/FTL/bin/pihole-FTL
${DIR}/build/FTL/bin/pihole-FTL --version
