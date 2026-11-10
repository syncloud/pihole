#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=${1:?usage: build.sh <version>}

${DIR}/../apt.sh wget

BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}/bin

cd ${DIR}/../build
${DIR}/../download-retry.sh https://github.com/pi-hole/pi-hole/archive/v${VERSION}.tar.gz v${VERSION}.tar.gz
tar xf v${VERSION}.tar.gz
mv pi-hole-${VERSION} pi-hole
cd pi-hole

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/etc/pihole#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/var/log/pihole#/var/snap/pihole/common/log/pihole#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/run/pihole-FTL.pid#/var/snap/pihole/common/ftl.pid#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/.pihole#/snap/pihole/current#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/opt/pihole#/snap/pihole/current/advanced/Scripts#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/usr/local/bin#/snap/pihole/current/bin#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#piholeGitDir=.*#piholeGitDir="/snap/pihole/current"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#PIHOLE_COMMAND=.*#PIHOLE_COMMAND=true#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#killall -q#pkill -f#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#pihole-FTL#/snap/pihole/current/FTL/bin/pihole-FTL#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#dig +#/snap/pihole/current/bind9/bin/dig.sh +#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#grep -q "pihole"#grep -q $(systemctl show --property MainPID snap.pihole.ftl | cut -d= -f2)#g' {} +

sed -i 's#lsof -Pni:53#netstat -lnp | grep 53#g' pihole
sed -i 's#\[ "\$(cat "/proc/\${FTL_PID}/comm" 2>/dev/null)" = "[^"]*" \]#{ [ "$(cat "/proc/${FTL_PID}/comm" 2>/dev/null)" = "pihole-FTL" ] || grep -qa "pihole-FTL.bin" "/proc/${FTL_PID}/cmdline" 2>/dev/null; }#' advanced/Scripts/utils.sh
grep -qF 'grep -qa "pihole-FTL.bin" "/proc/${FTL_PID}/cmdline"' advanced/Scripts/utils.sh
sed -i 's#dig #/snap/pihole/current/bind9/bin/dig.sh #g' gravity.sh
sed -i '/^if \[\[ "${EUID}" -eq 0 \]\]; then$/,/^fi$/d' gravity.sh
if grep -q 'exec sudo -u pihole' gravity.sh; then exit 1; fi
sed -i 's#piholeDir="/etc/${basename}"#piholeDir="/var/snap/pihole/current/etc/pihole"#' gravity.sh
grep -q 'piholeDir="/var/snap/pihole/current/etc/pihole"' gravity.sh
sed -i 's#/etc/pihole/gravity.db#/var/snap/pihole/current/etc/pihole/gravity.db#' advanced/Templates/gravity_copy.sql
grep -q "'/var/snap/pihole/current/etc/pihole/gravity.db'" advanced/Templates/gravity_copy.sql

cp pihole ${BUILD_DIR}/bin
cp -r advanced ${BUILD_DIR}
cp -r "automated install" ${BUILD_DIR}
cp gravity.sh ${BUILD_DIR}/advanced/Scripts
