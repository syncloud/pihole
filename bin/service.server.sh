#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

export DATAROOTDIR=${SNAP_DATA}
export SYSCONFDIR=${SNAP_DATA}/config

case $1 in
start)
    exec $DIR/python/bin/python $DIR/python/bin/ldapcherryd -c ${SNAP_DATA}/config/ldapcherry.ini -p ${SNAP_DATA}/ldapcherry.pid
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
