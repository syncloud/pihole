#!/bin/sh -e
DIR=$( cd "$( dirname "$0" )" && cd .. && pwd )
${DIR}/lib/ld.so --library-path ${DIR}/lib ${DIR}/bin/nc "$@"
