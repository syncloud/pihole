#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /dev/shm/FTL*

mkdir -p ${SNAP_DATA}/etc/pihole ${SNAP_COMMON}/log/pihole

export FTLCONF_files_log_ftl=/dev/stdout
export FTLCONF_webserver_api_password=
export FTLCONF_webserver_port=127.0.0.1:8080
export FTLCONF_dns_upstreams="208.67.222.222;2620:0:ccc::2"
export FTLCONF_dns_listeningMode=all

exec $DIR/FTL/bin/pihole-FTL -f
