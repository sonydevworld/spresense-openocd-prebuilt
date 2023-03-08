# Create OpenOCD prebuilt packages for Win, Linux and MacOSX

Please clone OpenOCD source first because it may be customized by Sony Semiconductor Solutions.

## Building OpenOCD in MacOSX

### Prerequisites

- XCode developer tools (`xcode-select --install`)
- automake
- autoconf
- pkg-config
- libtool

You can use Homebrew package manager (https://brew.sh) to install tools other than XCode developer tools.

```bash
brew install automake autoconf pkg-config libtool
```

### Build packages for all architectures by Docker on MacOSX (recommend)

Install docker and above developer tools, and just run `build-all-packages.sh`. This script is just a batch script to perform build process as below section.

This script takes a long time because always perform a clean build.

After script successfully, output all of the package files (`*.tar.bz2`) into `dist` directory.

### Build packages individually by Docker 

You can use docker image using Dockerfile in current directory.
Type following command to build docker container.

```bash
docker build -t buildenv .
```

After container built successfully, you can use `build.sh` from docker.
Created docker image must be run in the root directory of this repository.

```bash
docker run -it --rm --mount "type=bind,source=$(pwd),destination=/work" -u $(id -u):$(id -g) buildenv ./build.sh [win32|win64|linux32]
```

If no options to build.sh, create Linux 64 bit package. Available options are `win32`, `win64` and `linux32`.

## Building OpenOCD in Linux

As doing in above docker container image, you can run `build.sh` on Ubuntu 18.04 (bionic).
Please refer `Dockerfile` to necessary build tools for creating linux and windows packages.

In this way, MacOSX package can not built.
