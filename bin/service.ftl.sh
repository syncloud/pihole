#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec $DIR/FTL/bin/pihole-FTL debug
-- -C /var/snap/pihole/current/config/01-pihole.conf
