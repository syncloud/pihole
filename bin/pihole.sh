#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
case "$1" in
    -g|updateGravity)
        exec flock ${SNAP_DATA}/gravity.lock ${DIR}/bin/pihole "$@"
        ;;
esac
exec ${DIR}/bin/pihole "$@"
