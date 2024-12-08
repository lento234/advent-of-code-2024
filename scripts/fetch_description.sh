#!/bin/bash
if [[ $# != 1 ]]; then
    >&2 echo "Usage: $0 <day>"
    exit 1
fi

DAY=$1
ROOTDIR=$(git rev-parse --show-toplevel)

# Fetch day $DAY using curl and cookie
# convert from HTML to pandoc
# delete all unwanted lines and HTML tags containing {}
# write to README.md
curl -s -H "Cookie: session=$(cat ${ROOTDIR}/.cookie)" https://adventofcode.com/2024/day/${DAY#0} \
    | pandoc -f html -t markdown \
    | sed -e '/<div>/,/::: {role="main"}/d' -e '/Both parts of this puzzle are complete!/,//d' -e 's/{[^{}]*}//g'
