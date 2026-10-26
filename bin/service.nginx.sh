#!/bin/bash -e

${SNAP}/bin/wait-for-configure.sh
/bin/rm -f ${SNAP_COMMON}/web.socket
exec ${SNAP}/nginx/bin/nginx.sh -c ${SNAP_DATA}/config/nginx.conf -p ${SNAP}/nginx -e stderr
