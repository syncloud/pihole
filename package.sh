#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

if [[ -z "$2" ]]; then
    echo "usage $0 app version"
    exit 1
fi

NAME=$1
ARCH=$(uname -m)
VERSION=$2

BUILD_DIR=${DIR}/build/app
mkdir -p ${BUILD_DIR}

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}/config.templates
cp -r ${DIR}/hooks ${BUILD_DIR}

mv ${DIR}/build/bind9 ${BUILD_DIR}
mv ${DIR}/build/nginx ${BUILD_DIR}
mv ${DIR}/build/php7 ${BUILD_DIR}/php
mv ${DIR}/build/python ${BUILD_DIR}
mv ${DIR}/build/sqlite ${BUILD_DIR}
mv ${DIR}/build/lib ${BUILD_DIR}
mv ${DIR}/build/AdminLTE ${BUILD_DIR}/web

cd ${BUILD_DIR}/web
find . -name "*.php" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +
find . -name "*.php" -exec sed -i 's#/var/log#/var/snap/pihole/common/log#g' {} +
find . -name "*.js" -exec sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' {} +

cd ${DIR}/build/pi-hole
sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' advanced/Templates/gravity_copy.sql
sed -i 's#/etc/pihole#/var/snap/pihole/current/config/pihole#g' gravity.sh
sed -i 's#/etc/.pihole#/snap/pihole/current#g' gravity.sh
sed -i 's#piholeDir="/etc/${basename}"#piholeDir="/var/snap/pihole/current/config/pihole"#g' gravity.sh
sed -i 's#piholeGitDir=.*#piholeGitDir="/snap/pihole/current"#g' gravity.sh
sed -i 's#/opt/pihole#/snap/pihole/current/advanced/Scripts#g' gravity.sh
sed -i 's#sqlite3#/snap/pihole/current/bin/sqlite.sh#g' gravity.sh
sed -i 's#sqlite3#/snap/pihole/current/bin/sqlite.sh#g' advanced/Scripts/database_migration/gravity-db.sh
sed -i 's#/etc/.pihole#/snap/pihole/current#g' advanced/Scripts/database_migration/gravity-db.sh
sed -i 's#dig#/snap/pihole/current/bin/dig.sh#g' gravity.sh
sed -i 's#PIHOLE_COMMAND=.*#PIHOLE_COMMAND=true#g' gravity.sh
cp gravity.sh ${BUILD_DIR}/bin
cp -r advanced ${BUILD_DIR}

cp ${DIR}/build/FTL/pihole-FTL ${BUILD_DIR}/bin

cd ${DIR}/build
mkdir ${BUILD_DIR}/META
echo ${NAME} >> ${BUILD_DIR}/META/app
echo ${VERSION} >> ${BUILD_DIR}/META/version

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

mkdir ${DIR}/artifact
cp ${DIR}/${PACKAGE} ${DIR}/artifact