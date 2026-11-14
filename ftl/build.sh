#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=${1:?usage: build.sh <version>}
NETTLE_VERSION=3.9

${DIR}/../apt.sh wget build-essential cmake git m4 libgmp-dev libidn2-dev libunistring-dev libreadline-dev xxd patch

BUILD_DIR=${DIR}/../build/snap/FTL
mkdir -p ${BUILD_DIR}/bin ${BUILD_DIR}/lib

cd ${DIR}/../build

${DIR}/../download-retry.sh https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz nettle-${NETTLE_VERSION}.tar.gz
tar xf nettle-${NETTLE_VERSION}.tar.gz
cd nettle-${NETTLE_VERSION}
MULTIARCH=$(gcc -print-multiarch)
./configure --prefix=/usr --libdir=/usr/lib/${MULTIARCH}
make -j$(nproc)
make install
ldconfig
cd ${DIR}/../build

${DIR}/../download-retry.sh https://github.com/pi-hole/FTL/archive/v${VERSION}.tar.gz FTL-${VERSION}.tar.gz
tar xf FTL-${VERSION}.tar.gz
mv FTL-${VERSION} FTL-src
cd FTL-src
for p in ${DIR}/patches/*.patch; do
  patch -p1 < ${p}
done

grep -rlE '/etc/pihole|/var/log/pihole|/run/pihole-FTL.pid' src | xargs sed -i \
  -e 's#/etc/pihole#/var/snap/pihole/current/etc/pihole#g' \
  -e 's#/var/log/pihole#/var/snap/pihole/common/log/pihole#g' \
  -e 's#/run/pihole-FTL.pid#/var/snap/pihole/common/ftl.pid#g'

export GIT_BRANCH=master GIT_VERSION=v${VERSION} GIT_TAG=v${VERSION} GIT_HASH=v${VERSION}
mkdir cmake
cd cmake
cmake -DPIHOLE_SCRIPT=/snap/pihole/current/bin/pihole.sh -DFTL_EXIT_ON_RESTART=ON ..
cmake --build . -- -j$(nproc)
./pihole-FTL verify
grep -q '/snap/pihole/current/bin/pihole.sh' pihole-FTL
mv pihole-FTL ${BUILD_DIR}/bin/pihole-FTL.bin

for lib in $(ldd ${BUILD_DIR}/bin/pihole-FTL.bin | grep '=>' | awk '{print $3}'); do
  cp -L ${lib} ${BUILD_DIR}/lib/
done
cp -L $(ldd ${BUILD_DIR}/bin/pihole-FTL.bin | grep 'ld-linux' | awk '{print $1}') ${BUILD_DIR}/lib/ld.so

cat > ${BUILD_DIR}/bin/pihole-FTL <<'EOF'
#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/lib/ld.so --library-path ${DIR}/lib ${DIR}/bin/pihole-FTL.bin "$@"
EOF
chmod +x ${BUILD_DIR}/bin/pihole-FTL

${BUILD_DIR}/bin/pihole-FTL --version
