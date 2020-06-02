#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

export LD_LIBRARY_PATH=${DIR}/sqlite/lib

${DIR}/sqlite/bin/sqlite3 "$@"
