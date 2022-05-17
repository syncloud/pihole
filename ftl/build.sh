#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

apt-get update
apt-get install -y libgmp-dev m4 libidn11-dev libreadline-dev xxd cmake

BUILD_DIR=${DIR}/../build
cd ${BUILD_DIR}/nettle
./configure --help
./configure --prefix=${BUILD_DIR}
make -j4
make install

cd ${DIR}/build/FTL
sed -i 's#/var/tmp#/var/snap/pihole/current/temp#g' src/database/sqlite3.c
sed -i 's#/usr/tmp#/var/snap/pihole/current/temp#g' src/database/sqlite3.c
sed -i 's#/var/run#/var/snap/pihole/current/run#g' src/dnsmasq/config.h
sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' src/config.c
sed -i 's#/var/log#/var/snap/pihole/common/log#g' src/config.c
export CFLAGS=-I${BUILD_DIR}/include
export CMAKE_PREFIX_PATH=${BUILD_DIR}/lib
./build.sh
ldd pihole-FTL
mv pihole-FTL pihole-FTL.bin
cp $DIR/pihole-FTL .
cp /lib/*/libm.so* ${BUILD_DIR}/lib
cp /lib/*/librt.so* ${BUILD_DIR}/lib
cp /usr/local/*/libgcc_s.so* ${BUILD_DIR}/lib
cp /lib/*/libpthread.so* ${BUILD_DIR}/lib
cp /lib/*/libc.so* ${BUILD_DIR}/lib
cp /lib/*-linux*/ld-*.so ${BUILD_DIR}/lib/ld.so
export LD_LIBRARY_PATH=${BUILD_DIR}/lib
ldd pihole-FTL.bin