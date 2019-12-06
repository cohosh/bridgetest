#!/bin/bash

set -e

CASE="${1:?}"
SITE="${2:?}"

if ! [[ "$CASE" =~ ^(obfs4)$ ]]; then
    echo 'Error, please choose a valid test type from [obfs4]'
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
esac