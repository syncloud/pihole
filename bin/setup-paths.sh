mkdir -p ${SNAP_DATA}/etc/pihole ${SNAP_COMMON}/log/pihole
[ -L /etc/pihole ] || { rm -rf /etc/pihole; ln -s ${SNAP_DATA}/etc/pihole /etc/pihole; }
[ -L /var/log/pihole ] || { rm -rf /var/log/pihole; ln -s ${SNAP_COMMON}/log/pihole /var/log/pihole; }
ln -sf ${SNAP_COMMON}/ftl.pid /run/pihole-FTL.pid
