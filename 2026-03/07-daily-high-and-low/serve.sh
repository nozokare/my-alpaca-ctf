#!/bin/sh
socat tcp-listen:1337,reuseaddr,fork exec:"python3 handout/server.py"