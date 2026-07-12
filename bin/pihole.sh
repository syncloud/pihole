#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
mkdir -p ${SNAP_DATA}/etc/pihole ${SNAP_COMMON}/log/pihole
exec ${DIR}/bin/pihole "$@"
