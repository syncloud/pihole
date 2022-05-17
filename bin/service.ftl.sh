#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec $DIR/FTL/bin/pihole-FTL -C $DIR/config/pihole/dnsmasq.conf debug
