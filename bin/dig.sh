#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

export LD_LIBRARY_PATH=${DIR}/bind9/lib

${DIR}/bind9/bin/dig "$@"