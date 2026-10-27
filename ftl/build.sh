#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
FTL_COMMIT=968754d8bd795982f1d070bb24f2496ddd2460fe
NETTLE_VERSION=3.9

${DIR}/../apt.sh wget build-essential cmake git m4 libgmp-dev libidn2-dev libunistring-dev libreadline-dev xxd

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

${DIR}/../download-retry.sh https://github.com/cyberb/FTL/archive/${FTL_COMMIT}.tar.gz FTL-${FTL_COMMIT}.tar.gz
tar xf FTL-${FTL_COMMIT}.tar.gz
mv FTL-${FTL_COMMIT} FTL-src
cd FTL-src

grep -rlE '/etc/pihole|/var/log/pihole|/run/pihole-FTL.pid' src | xargs sed -i \
  -e 's#/etc/pihole#/var/snap/pihole/current/etc/pihole#g' \
  -e 's#/var/log/pihole#/var/snap/pihole/common/log/pihole#g' \
  -e 's#/run/pihole-FTL.pid#/var/snap/pihole/common/ftl.pid#g'

mkdir cmake
cd cmake
cmake -DPIHOLE_SCRIPT=/snap/pihole/current/bin/pihole.sh "-DFTL_RESTART_COMMAND=systemctl --no-block restart snap.pihole.ftl.service" ..
cmake --build . -- -j$(nproc)
./pihole-FTL verify
grep -q '/snap/pihole/current/bin/pihole.sh' pihole-FTL
grep -q 'systemctl --no-block restart snap.pihole.ftl.service' pihole-FTL
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
