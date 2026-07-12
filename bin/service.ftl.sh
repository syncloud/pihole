#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /dev/shm/FTL*

mkdir -p ${SNAP_DATA}/etc/pihole ${SNAP_COMMON}/log/pihole
rm -f ${SNAP_COMMON}/ftl.socket

export FTLCONF_files_log_ftl=/dev/stdout
export FTLCONF_webserver_api_password=
export FTLCONF_webserver_paths_webroot=${DIR}/web
export FTLCONF_webserver_paths_webhome=/admin/
export FTLCONF_dns_upstreams="208.67.222.222;2620:0:ccc::2"
export FTLCONF_dns_listeningMode=all

# CivetWeb unix socket (patched-in USE_X_DOM_SOCKET) — no TCP port, nginx fronts web.socket
$DIR/FTL/bin/pihole-FTL --config webserver.port "x${SNAP_COMMON}/ftl.socket" >/dev/null 2>&1 || true

exec $DIR/FTL/bin/pihole-FTL -f
