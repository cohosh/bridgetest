#!/bin/bash

set -e

CASE="${1:?}"
SITE="${2:?}"

if ! [[ "$CASE" =~ ^(obfs4|snowflake)$ ]]; then
    echo 'Error, please choose a valid test type from ["obfs4"|"snowflake"]'
    exit 1
fi

dirname="$PWD"
date=$(date -u +%Y%m%d-%H%M)
logdirname="log/$CASE/$SITE/$date"
mkdir -p "$logdirname"
cd "$logdirname"

case $CASE in
    'obfs4')
        "$dirname/obfs4test" "$dirname/bridge_lines.txt"
        ;;
    'snowflake')
        # First test reachability of STUN servers
        "$dirname/stun-test/stun-test"
        # Throughput/reachibility test of 10 snowflakes
        "$dirname/snowflaketest"
        ;;
esac

chown -R $UID:$UID $dirname/log/
tar -czvf $dirname/log/$CASE/$SITE/$date.tar.gz $dirname/log/$CASE/$SITE/$date
chown -R $UID:$UID $dirname/log/$CASE/$SITE/$date.tar.gz
rm -rf $dirname/log/$CASE/$SITE/$date
