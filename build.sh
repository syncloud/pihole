#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}
cp -r ${DIR}/meta ${BUILD_DIR}

mv ${DIR}/build/bind9 ${BUILD_DIR}
mv ${DIR}/build/nginx ${BUILD_DIR}
mv ${DIR}/build/AdminLTE ${BUILD_DIR}/web
mv ${DIR}/build/FTL ${BUILD_DIR}

cp ${DIR}/build/gravity/gravity ${BUILD_DIR}/bin/gravity
cp ${DIR}/build/cli/cli ${BUILD_DIR}/bin/cli

cd ${BUILD_DIR}/web
find . -name "*.php" -exec sed -i 's#/etc/pihole/setupVars.conf#/var/snap/pihole/current/setupVars.conf#g' {} +
find . -name "*.php" -exec sed -i 's#/etc/pihole/dns-servers.conf#/var/snap/pihole/current/config/pihole/dns-servers.conf#g' {} +

find . -name "*.php" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +
find . -name "*.php" -exec sed -i 's#/var/log#/var/snap/pihole/common/log#g' {} +
find . -name "*.php" -exec sed -i 's#sudo pihole#snap run pihole.cli#g' {} +
find . -name "*.php" -exec sed -i 's#pidof pihole-FTL#systemctl show --property MainPID snap.pihole.ftl | cut -d= -f2#g' {} +
find . -name "*.js" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +

cd ${DIR}/build/pi-hole

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#piholeGitDir=.*#piholeGitDir="/snap/pihole/current"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#PIHOLE_COMMAND=.*#PIHOLE_COMMAND=true#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#dig +#/snap/pihole/current/bind9/bin/dig.sh +#g' {} +

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#killall -q#pkill -f#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#pihole-FTL#/snap/pihole/current/FTL/bin/pihole-FTL#g' {} +

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/.pihole#/snap/pihole/current#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/opt/pihole#/snap/pihole/current/advanced/Scripts#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/usr/local/bin#/snap/pihole/current/bin#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#grep -q "pihole"#grep -q $(systemctl show --property MainPID snap.pihole.ftl | cut -d= -f2)#g' {} +

sed -i 's#lsof -Pni:53#netstat -lnp | grep 53#g' pihole
sed -i 's#IPv4\.\*UDP#udp #g' pihole
sed -i 's#IPv4\.\*TCP#tcp #g' pihole
sed -i 's#IPv6\.\*UDP#udp6#g' pihole
sed -i 's#IPv6\.\*TCP#tcp6#g' pihole

sed -i 's#dig #/snap/pihole/current/bind9/bin/dig.sh #g' gravity.sh

cp gravity.sh ${BUILD_DIR}/bin
cp pihole ${BUILD_DIR}/bin
cp -r advanced ${BUILD_DIR}
cp -r "automated install" ${BUILD_DIR}
cp gravity.sh ${BUILD_DIR}/advanced/Scripts
ln -sf ../FTL/bin/pihole-FTL ${BUILD_DIR}/bin/pihole-FTL
