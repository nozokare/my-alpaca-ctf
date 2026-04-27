#!/bin/bash
branch=$(git branch --show-current 2>/dev/null)
type=${branch:0:5}
year=${branch:6:4}
month=${branch:10:2}
day=${branch:12:2}

path=$(realpath ${0%/*}/../${year}-${month}/${day}-${type}-*)
if [ -d "$path" ]; then
    echo "$path"
else
    exit 1
fi
