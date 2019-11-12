#!/bin/sh

if [ -z "`which docker 2>/dev/null`" ]; then
    echo "Please install docker first!"
fi

if [ "`uname -s`" = "Darwin" ]; then
    # Build MacOS package
    ./build.sh
fi

# Make sure want to be build container exists

docker build -t buildenv .

# Linux 64 bit and other supported architectures

docker run -it --rm --mount "type=bind,source=$(pwd),destination=/work" --name build buildenv ./build.sh
docker run -it --rm --mount "type=bind,source=$(pwd),destination=/work" --name build buildenv ./build.sh linux32
docker run -it --rm --mount "type=bind,source=$(pwd),destination=/work" --name build buildenv ./build.sh win32
docker run -it --rm --mount "type=bind,source=$(pwd),destination=/work" --name build buildenv ./build.sh win64
