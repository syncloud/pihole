#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
. ${DIR}/bin/setup-paths.sh
exec ${DIR}/bin/pihole "$@"
