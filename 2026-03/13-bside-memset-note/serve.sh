#!/bin/sh
cd "$(dirname "$0")/handout"
socat tcp-listen:1337,fork,reuseaddr exec:'./chal',stderr
