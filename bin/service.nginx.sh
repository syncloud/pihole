#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
/bin/rm -f ${SNAP_COMMON}/web.socket
${DIR}/nginx/sbin/nginx -t -c ${SNAP_DATA}/config/nginx.conf -p ${DIR}/nginx -e stderr
exec ${DIR}/nginx/sbin/nginx -c ${SNAP_DATA}/config/nginx.conf -p ${DIR}/nginx -e stderr
