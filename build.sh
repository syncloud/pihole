#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}
cp -r ${DIR}/hooks ${BUILD_DIR}
cp -r ${DIR}/meta ${BUILD_DIR}

mv ${DIR}/build/bind9 ${BUILD_DIR}
mv ${DIR}/build/nginx ${BUILD_DIR}
mv ${DIR}/build/AdminLTE ${BUILD_DIR}/web
mv ${DIR}/build/FTL ${BUILD_DIR}

cd ${BUILD_DIR}/web
find . -name "*.php" -exec sed -i 's#/etc/pihole/setupVars.conf#/var/snap/pihole/current/setupVars.conf#g' {} +
find . -name "*.php" -exec sed -i 's#/etc/pihole/dns-servers.conf#/var/snap/pihole/current/config/pihole/dns-servers.conf#g' {} +

find . -name "*.php" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +
find . -name "*.php" -exec sed -i 's#/var/log#/var/snap/pihole/common/log#g' {} +
find . -name "*.php" -exec sed -i 's#sudo pihole#snap run pihole.cli#g' {} +
find . -name "*.php" -exec sed -i 's#pidof pihole-FTL#systemctl show --property MainPID snap.pihole.ftl | cut -d= -f2#g' {} +
find . -name "*.js" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +

cd ${DIR}/build/pi-hole
find . -name "*.sql" -exec sed -i 's#/etc/pihole/gravity.db#/var/snap/pihole/current/gravity.db#g' {} +

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/pihole/setupVars.conf#/var/snap/pihole/current/setupVars.conf#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#gravityDBfile=.*"#gravityDBfile="/var/snap/pihole/current/gravity.db"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#gravityTEMPfile=.*"#gravityTEMPfile="/var/snap/pihole/current/gravity_temp.db"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#setupVars=.*"#setupVars="/var/snap/pihole/current/setupVars.conf"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#piholeDir=.*"#piholeDir="/var/snap/pihole/current/config/pihole"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#piholeGitDir=.*#piholeGitDir="/snap/pihole/current"#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#PIHOLE_COMMAND=.*#PIHOLE_COMMAND=true#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#pihole-FTL sqlite3#/snap/pihole/current/FTL/bin/pihole-FTL sqlite3#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#nc 127.0.0.1#/snap/pihole/current/netcat/bin/nc.sh 127.0.0.1#g' {} +
#find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#sqlite3#/snap/pihole/current/sqlite/bin/sqlite.sh#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#dig +#/snap/pihole/current/bind9/bin/dig.sh +#g' {} +
sed -i 's#dig #/snap/pihole/current/bind9/bin/dig.sh #g' gravity.sh

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#killall -q#pkill -f#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#service pihole-FTL restart#snap restart pihole.ftl#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#pkill -HUP pihole-FTL#snap restart pihole.ftl#g' {} +

find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/dnsmasq.d#/var/snap/pihole/current/config#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/etc/.pihole#/snap/pihole/current#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/opt/pihole#/snap/pihole/current/advanced/Scripts#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#/usr/local/bin#/snap/pihole/current/bin#g' {} +
find . -regex "\(.*.sh\|.*pihole\)" -exec sed -i 's#grep -q "pihole"#grep -q $(systemctl show --property MainPID snap.pihole.ftl | cut -d= -f2)#g' {} +

sed -i 's#lsof -Pni:53#netstat -lnp | grep 53#g' pihole
sed -i 's#IPv4\.\*UDP#udp #g' pihole
sed -i 's#IPv4\.\*TCP#tcp #g' pihole
sed -i 's#IPv6\.\*UDP#udp6#g' pihole
sed -i 's#IPv6\.\*TCP#tcp6#g' pihole

cp gravity.sh ${BUILD_DIR}/bin
cp pihole ${BUILD_DIR}/bin
cp -r advanced ${BUILD_DIR}
ln -s /snap/pihole/current/bin/gravity.sh ${BUILD_DIR}/advanved/Scripts/gravity.sh
cp -r "automated install" ${BUILD_DIR}
#cp advanced/dnsmasq.conf.original ${BUILD_DIR}/config.templates/dnsmasq.conf
#cp advanced/01-pihole.conf ${BUILD_DIR}/config.templates/01-pihole.conf

