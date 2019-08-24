#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage $0 app version"
    exit 1
fi

NAME=$1
NETTLE_VERSION=3.4
GMP_VERSION=6.1.2
FTL_VERSION=4.3.1
ARCH=$(uname -m)
VERSION=$2

DOWNLOAD_URL=http://artifact.syncloud.org/3rdparty

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build/${NAME}
mkdir -p ${BUILD_DIR}

cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}/

wget --progress=dot:giga ${DOWNLOAD_URL}/python-${ARCH}.tar.gz
tar xf python-${ARCH}.tar.gz
mv python ${BUILD_DIR}/

${BUILD_DIR}/python/bin/pip install -r ${DIR}/requirements.txt

cp -r ${DIR}/bin ${BUILD_DIR}
#cp -r ${DIR}/config ${BUILD_DIR}/config.templates
#cp -r ${DIR}/hooks ${BUILD_DIR}

cd ${DIR}/build
wget --progress=dot:giga https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz
tar xf nettle-${NETTLE_VERSION}.tar.gz
cd nettle-${NETTLE_VERSION}
./configure --help
./configure --prefix=${BUILD_DIR}
make
make install

#apt update
#apt install libgmp-dev
wget --progress=dot:giga https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2
tar xf gmp-${GMP_VERSION}.tar.bz2
cd gmp-${GMP_VERSION}
if [[ $ARCH == "x86_64" ]]; then
    export CFLAGS="-fPIC -O2 -pedantic -fomit-frame-pointer -m64 -mtune=slm -march=slm" 
else
    expprt CFLAGS="-fPIC -O2 -pedantic -fomit-frame-pointer -march=armv7-a -mfloat-abi=hard -mfpu=neon -mtune=cortex-a15" 
fi
./configure --help
./configure --prefix=${BUILD_DIR}
make
make install

wget --progress=dot:giga https://github.com/pi-hole/FTL/archive/v${FTL_VERSION}.tar.gz
tar xf v${FTL_VERSION}.tar.gz
cd FTL-${FTL_VERSION}
for f in ${DIR}/patches/*.patch
do
  patch -p0 < $f
done
sed -i 's#/usr/local/lib#'${BUILD_DIR}/lib'#g' Makefile
export CFLAGS=-I${BUILD_DIR}/include
make
cp pihole-FTL ${BUILD_DIR}/bin/pihole-FTL

mkdir ${DIR}/build/${NAME}/META
echo ${NAME} >> ${DIR}/build/${NAME}/META/app
echo ${VERSION} >> ${DIR}/build/${NAME}/META/version

echo "snapping"
SNAP_DIR=${DIR}/build/snap
ARCH=$(dpkg-architecture -q DEB_HOST_ARCH)
rm -rf ${DIR}/*.snap
mkdir ${SNAP_DIR}
cp -r ${BUILD_DIR}/* ${SNAP_DIR}/
cp -r ${DIR}/snap/meta ${SNAP_DIR}/
cp ${DIR}/snap/snap.yaml ${SNAP_DIR}/meta/snap.yaml
echo "version: $VERSION" >> ${SNAP_DIR}/meta/snap.yaml
echo "architectures:" >> ${SNAP_DIR}/meta/snap.yaml
echo "- ${ARCH}" >> ${SNAP_DIR}/meta/snap.yaml

PACKAGE=${NAME}_${VERSION}_${ARCH}.snap
echo ${PACKAGE} > ${DIR}/package.name
mksquashfs ${SNAP_DIR} ${DIR}/${PACKAGE} -noappend -comp xz -no-xattrs -all-root
