#!/bin/sh

which docker >/dev/null || {
    echo "Please install docker first!";
    exit 1;
}

if [ "`uname -s`" = "Darwin" ]; then
    # Build MacOS package
    ./build.sh
fi

# Make sure want to be build container exists

docker build -t build-openocd .

# Linux 64 bit and other supported architectures

./build-wrapper.sh
TARGET=win64 ./build-wrapper.sh
