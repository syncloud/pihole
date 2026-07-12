#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
FTL_VERSION=v6.7

apt-get update
apt-get install -y wget build-essential cmake git m4 nettle-dev libgmp-dev libidn2-dev libunistring-dev libreadline-dev xxd

BUILD_DIR=${DIR}/../build/snap/FTL
mkdir -p ${BUILD_DIR}/bin

cd ${DIR}/../build
wget --progress=dot:giga https://github.com/pi-hole/FTL/archive/${FTL_VERSION}.tar.gz
tar xf ${FTL_VERSION}.tar.gz
mv FTL-* FTL-src
cd FTL-src

# relocate hardcoded FHS paths into the snap layout (matches core/build.sh seds)
grep -rlE '/etc/pihole|/var/log/pihole|/run/pihole-FTL.pid' src | xargs sed -i \
  -e 's#/etc/pihole#/var/snap/pihole/current/etc/pihole#g' \
  -e 's#/var/log/pihole#/var/snap/pihole/common/log/pihole#g' \
  -e 's#/run/pihole-FTL.pid#/var/snap/pihole/common/ftl.pid#g'

# enable CivetWeb unix-domain-socket listening ("x<path>" port syntax)
sed -i 's/TIMER_RESOLUTION=1000/TIMER_RESOLUTION=1000\n    USE_X_DOM_SOCKET/' src/webserver/civetweb/CMakeLists.txt

bash build.sh
mv pihole-FTL ${BUILD_DIR}/bin/pihole-FTL
${BUILD_DIR}/bin/pihole-FTL --version
