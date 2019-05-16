#!/bin/bash

set -e

SITE="${1:?}"

dirname="$PWD"
logdirname="snowflake_log/$SITE/$(date -u +%Y%m%d-%H%M)"
mkdir -p "$logdirname"
cd "$logdirname" && "$dirname/snowflaketest"
