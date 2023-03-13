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

### Build packages for target host

Run following instruction with OPENOCDDIR as spresense-openocd directory in abs path.

```bash
OPENOCDDIR=$(pwd)/spresense-openocd ./build.sh
```

### Build packages individually by Docker 

It can be built for linux and windows binaries.
You can use docker image using Dockerfile in current directory.
Type following command to build docker container.

```bash
docker build -t build-openocd .
```

After container built successfully, you can use `build-wrapper.sh`.

```bash
build-wrapper.sh [linux64|win64]
```

If no options to build-wrapper.sh, create Linux 64 bit package. Available options are `win32`, `win64` and `linux32`.

The OpenOCD source directory is $(pwd)/spresense-openocd used in default.
If you want to change it, set OPENOCDDIR variable in abs path.
