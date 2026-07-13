#!/bin/sh
DIR=$( cd "$( dirname "$0" )" && cd .. && pwd )
LIBS="$(echo ${DIR}/lib/*-linux-gnu*):$(echo ${DIR}/usr/lib/*-linux-gnu*)"
exec ${DIR}/lib/*-linux*/ld-*.so --library-path "$LIBS" ${DIR}/usr/bin/dig "$@"
