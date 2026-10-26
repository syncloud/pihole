#!/bin/bash -e

${SNAP}/bin/wait-for-configure.sh
exec ${SNAP}/bin/gravity
