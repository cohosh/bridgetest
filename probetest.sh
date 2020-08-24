#!/bin/bash

set -e

CASE="${1:?}"
SITE="${2:?}"

if ! [[ "$CASE" =~ ^(obfs4|snowflake)$ ]]; then
    echo 'Error, please choose a valid test type from ["obfs4"|"snowflake"]'
    exit 1
fi

dirname="$PWD"
logdirname="log/$CASE/$SITE/$(date -u +%Y%m%d-%H%M)"
mkdir -p "$logdirname"
cd "$logdirname"

case $CASE in
    'obfs4')
        "$dirname/obfs4test" "$dirname/bridge_lines.txt"
        ;;
    'snowflake')
        # First test reachability of STUN servers
        "$dirname/stun-test/stun-test"
        # Throughput/reachibility test of 100 snowflakes
        "$dirname/snowflaketest"
        # Process .pcap files and delete
        "$dirname/snowflake-throughput.py" > snowflake-throughput.csv
        rm *.pcap
        ;;
esac
