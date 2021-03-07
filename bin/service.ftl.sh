#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec $DIR/bin/pihole-FTL debug 2>&1 | logger -t pihole-ftl
