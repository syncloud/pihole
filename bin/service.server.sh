#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

if [[ -z "$1" ]]; then
    echo "usage $0 [start]"
    exit 1
fi

case $1 in
start)
    $DIR/bin/pihole debug
    ;;
*)
    echo "not valid command"
    exit 1
    ;;
esac
