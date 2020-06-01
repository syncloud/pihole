#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage $0 app version"
    exit 1
fi

NAME=$1
NETTLE_VERSION=3.5
GMP_VERSION=6.1.2
FTL_VERSION=dcafd2e21b18410db983443522b708bd8f3f2cc0
WEB_VERSION=development
API_VERSION=development
ARCH=$(uname -m)
VERSION=$2
NODE_VERSION=10.15.1
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download/1

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build/${NAME}
mkdir -p ${BUILD_DIR}

ls -la ${DIR}/cache || true

cd ${DIR}/build

wget --progress=dot:giga ${DOWNLOAD_URL}/bind9-${ARCH}.tar.gz
tar xf bind9-${ARCH}.tar.gz
mv bind9 ${BUILD_DIR}/

wget --progress=dot:giga ${DOWNLOAD_URL}/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}/

wget --progress=dot:giga ${DOWNLOAD_URL}/python-${ARCH}.tar.gz
tar xf python-${ARCH}.tar.gz
mv python ${BUILD_DIR}/

${BUILD_DIR}/python/bin/pip install -r ${DIR}/requirements.txt

wget --progress=dot:giga ${DOWNLOAD_URL}/sqlite-${ARCH}.tar.gz
tar xf sqlite-${ARCH}.tar.gz
mv sqlite ${BUILD_DIR}/

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}/config.templates
cp -r ${DIR}/hooks ${BUILD_DIR}
cp -r ${DIR}/etc ${BUILD_DIR}

cd ${DIR}/build
wget https://github.com/cyberb/api/archive/${API_VERSION}.tar.gz
#wget https://github.com/pi-hole/api/archive/${API_VERSION}.tar.gz
tar xf ${API_VERSION}.tar.gz
rm ${API_VERSION}.tar.gz
cd api-${API_VERSION}
sed 's#/etc/pihole/API.toml#/var/snap/pihole/current/config/api.toml#g' -i src/env/config/root_config.rs
find . -name "*.rs" -exec sed -i 's#/etc/pihole#/var/snap/pihole/common/etc/pihole#g' {} + 
find . -name "*.rs" -exec sed -i 's#/var/log#/var/snap/pihole/common/log#g' {} + 
if [[ -d ${DIR}/cache/.cargo && -d ${DIR}/cache/.rustup ]]; then
    cp -r ${DIR}/cache/.cargo ${HOME}
    cp -r ${DIR}/cache/.rustup ${HOME}
else
    curl https://sh.rustup.rs -sSf | sh -s -- -y
fi
source ~/.cargo/env
cargo build --release
cp target/release/pihole_api ${BUILD_DIR}/bin/api

cd ${DIR}/build
wget https://github.com/cyberb/pi-hole/archive/feature/api.tar.gz
tar xf api.tar.gz
rm api.tar.gz
cd pi-hole-feature-api
#wget https://github.com/cyberb/pi-hole/archive/development.tar.gz
#tar xf development.tar.gz
#rm development.tar.gz
#cd pi-hole-development
sed -i 's#/etc/pihole#/var/snap/pihole/common/etc/pihole#g' gravity.sh
sed -i 's#/etc/.pihole#/snap/pihole/current#g' gravity.sh
sed -i 's#piholeDir="/etc/${basename}"#piholeDir="/var/snap/pihole/common/etc/pihole"#g' gravity.sh
sed -i 's#piholeGitDir=.*#piholeGitDir="/snap/pihole/current"#g' gravity.sh
sed -i 's#/opt/pihole#/snap/pihole/current/advanced/Scripts#g' gravity.sh
sed -i 's#sqlite3#/snap/pihole/current/sqlite/bin/sqlite3#g' gravity.sh
sed -i 's#sqlite3#/snap/pihole/current/sqlite/bin/sqlite3#g' advanced/Scripts/database_migration/gravity-db.sh
sed -i 's#/etc/.pihole#/snap/pihole/current#g' advanced/Scripts/database_migration/gravity-db.sh
sed -i 's#dig#/snap/pihole/current/bind9/bin/dig#g' gravity.sh
sed -i 's#PIHOLE_COMMAND=.*#PIHOLE_COMMAND=true#g' gravity.sh
cp gravity.sh ${BUILD_DIR}/bin
cp -r advanced ${BUILD_DIR}/

cd ${DIR}/build
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
source ~/.bashrc
nvm install ${NODE_VERSION}
wget https://github.com/cyberb/web/archive/${WEB_VERSION}.tar.gz
#wget https://github.com/pi-hole/web/archive/${WEB_VERSION}.tar.gz
tar xf ${WEB_VERSION}.tar.gz
rm ${WEB_VERSION}.tar.gz
mv web-${WEB_VERSION} web
cd web
sed '/"homepage": "."/d' -i package.json
cp -Rf ${DIR}/cache/node_modules node_modules || true
npm install
npm run build
ls -la
cp -r build ${BUILD_DIR}/web

cd ${DIR}/build
wget --progress=dot:giga https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz
tar xf nettle-${NETTLE_VERSION}.tar.gz
cd nettle-${NETTLE_VERSION}
./configure --help
./configure --prefix=${BUILD_DIR}
make
make install

cd ${DIR}/build
wget --no-check-certificate --progress=dot:giga https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2
tar xf gmp-${GMP_VERSION}.tar.bz2
cd gmp-${GMP_VERSION}
if [[ $ARCH == "x86_64" ]]; then
    export CFLAGS="-fPIC -O2 -pedantic -fomit-frame-pointer -m64 -mtune=slm -march=slm" 
else
    export CFLAGS="-fPIC -O2 -pedantic -fomit-frame-pointer -march=armv7-a -mfloat-abi=hard -mfpu=neon -mtune=cortex-a15" 
fi
./configure --help
./configure --prefix=${BUILD_DIR}
make
make install

cd ${DIR}/build
wget --progress=dot:giga https://github.com/pi-hole/FTL/archive/${FTL_VERSION}.tar.gz
tar xf ${FTL_VERSION}.tar.gz
cd FTL-${FTL_VERSION}
sed -i 's#/var/tmp#/var/snap/pihole/common/var/tmp#g' src/database/sqlite3.c
sed -i 's#/usr/tmp#/var/snap/pihole/common/usr/tmp#g' src/database/sqlite3.c
sed -i 's#/var/run#/var/snap/pihole/common/var/run#g' src/dnsmasq/config.h
sed -i 's#/usr/local/lib#'${BUILD_DIR}/lib'#g' Makefile
export CFLAGS=-I${BUILD_DIR}/include
make
cp pihole-FTL ${BUILD_DIR}/bin/ftl

#cache
rm -rf ${DIR}/cache/*
cp -r ${HOME}/.cargo ${DIR}/cache
cp -r ${HOME}/.rustup ${DIR}/cache
cp -r ${DIR}/build/web/node_modules ${DIR}/cache

cd ${DIR}/build
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
