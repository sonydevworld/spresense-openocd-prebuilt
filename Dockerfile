FROM ubuntu:bionic

RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get -qy install curl git build-essential libtool pkg-config automake autoconf libudev-dev && apt-get clean

# For 32bit linux target build
RUN apt-get -qy install gcc-i686-linux-gnu g++-i686-linux-gnu pkg-config-i686-linux-gnu libudev-dev:i386 && apt-get clean

# For Windows (32/64bit) target build
RUN apt-get -qy install mingw-w64 mingw-w64-tools && apt-get clean

CMD ["/bin/bash"]
WORKDIR /work
