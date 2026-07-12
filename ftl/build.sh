#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
FTL_VERSION=v6.7
NETTLE_VERSION=3.9

apt-get update
apt-get install -y wget build-essential cmake git m4 libgmp-dev libidn2-dev libunistring-dev libreadline-dev xxd

BUILD_DIR=${DIR}/../build/snap/FTL
mkdir -p ${BUILD_DIR}/bin ${BUILD_DIR}/lib

cd ${DIR}/../build

# nettle 3.9 (bookworm ships 3.8 which lacks nettle/balloon.h that FTL v6 needs)
wget --progress=dot:giga https://ftp.gnu.org/gnu/nettle/nettle-${NETTLE_VERSION}.tar.gz
tar xf nettle-${NETTLE_VERSION}.tar.gz
cd nettle-${NETTLE_VERSION}
./configure --prefix=/opt/nettle
make -j$(nproc)
make install
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

export CMAKE_PREFIX_PATH=/opt/nettle
bash build.sh
mv pihole-FTL ${BUILD_DIR}/bin/pihole-FTL.bin

# bundle shared libs + loader (from-source FTL is dynamically linked)
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
