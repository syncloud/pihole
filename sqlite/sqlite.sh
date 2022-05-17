#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
${DIR}/lib/ld-musl-*.so* --library-path ${DIR}/lib ${DIR}/usr/bin/sqlite3 "$@"
