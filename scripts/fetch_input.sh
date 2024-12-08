#!/bin/bash

if [[ $# != 1 ]]; then
    >&2 echo "Usage: $0 <day>"
    exit 1
fi

DAY=$1
ROOTDIR=$(git rev-parse --show-toplevel)

# Downloading input
curl -s -H "Cookie: session=$(cat ${ROOTDIR}/.cookie)" https://adventofcode.com/2024/day/${DAY#0}/input
