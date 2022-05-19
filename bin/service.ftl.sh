#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /dev/shm/FTL*
exec $DIR/FTL/bin/pihole-FTL debug -- -C /var/snap/pihole/current/config/dnsmasq.conf
