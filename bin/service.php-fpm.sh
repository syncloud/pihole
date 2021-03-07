#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

export LD_LIBRARY_PATH=${DIR}/php/lib
exec $DIR/php/sbin/php-fpm -y ${SNAP_DATA}/config/php-fpm.conf -c ${SNAP_DATA}/config/php.ini
