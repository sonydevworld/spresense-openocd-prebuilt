#!/usr/bin/env bash

OPENOCDDIR=$(realpath ${1:-spresense-openocd})

# This script uses docker container named as 'build-openocd'.
# Please run 'docker build -t build-openocd .' in this directory
# if you have no build-openocd image.

docker run -it --rm -u $(id -u):$(id -g) \
       -v $(pwd):/work \
       -v ${OPENOCDDIR}:/tmp/openocd build-openocd \
       ./build.sh $TARGET
