#!/bin/bash

set -x

LIBUSB_REPOS=https://github.com/libusb/libusb
LIBUSB_VERSION=1.0.21
LIBUSB_ARCHIVE=libusb-${LIBUSB_VERSION}.tar.bz2

HIDAPI_REPOS=https://github.com/libusb/hidapi
HIDAPI_VERSION=0.9.0
HIDAPI_ARCHIVE=hidapi-${HIDAPI_VERSION}.tar.gz

OPENOCD_VERSION=0.12.0
OPENOCD_MODVERSION=spr1

OPENOCDDIR=spresense-openocd

DISTDIR=/tmp/dist

OPENOCD_CONFIGOPTS="--disable-ftdi \
--disable-stlink \
--disable-ti-icdi \
--disable-ulink \
--disable-usb-blaster-2 \
--disable-ft232r \
--disable-vsllink \
--disable-xds110 \
--disable-osbdm \
--disable-opendous \
--disable-aice \
--disable-usbprog \
--disable-rlink \
--disable-armjtagew \
--enable-cmsis-dap \
--disable-kitprog \
--disable-usb-blaster \
--disable-presto \
--disable-openjtag \
--disable-jlink"

if [ ! -d $OPENOCDDIR ]; then
    echo "OpenOCD source directory not found. Please clone OpenOCD first!"
    exit 1
fi

if [ "$1" = "-h" ]; then
    echo "$0 [win32|win64]"
    exit 1
fi

# Determine native platform target

PLATFORM=`uname -s`

case "${PLATFORM}" in
    Linux)
        TARGET=linux64
        ;;
    Darwin)
        TARGET=macosx
        ;;
esac

# Take first option [win32|win64|linux32].

if [ "$1" = "win64" ]; then
    CROSS_COMPILE="--host=x86_64-w64-mingw32"
    TARGET=win64
fi
if [ "$1" = "win32" ]; then
    CROSS_COMPILE="--host=i686-w64-mingw32"
    TARGET=win32
fi
if [ "$1" = "linux32" ]; then
    CROSS_COMPILE="--host=i686-linux-gnu"
    TARGET=linux32
fi

if [ ! -z "${CROSS_COMPILE}" -a "${PLATFORM}" = "Darwin" ]; then
    echo Sorry, windows cross compile not supported in mac.
    exit 1
fi

rm -rf ${DISTDIR}

mkdir -p archives

# Download library sources

if [ ! -f archives/${LIBUSB_ARCHIVE} ]; then
    curl -L ${LIBUSB_REPOS}/releases/download/v${LIBUSB_VERSION}/${LIBUSB_ARCHIVE} > archives/${LIBUSB_ARCHIVE}
fi
if [ ! -f archives/${HIDAPI_ARCHIVE} ]; then
    curl -L ${HIDAPI_REPOS}/archive/${HIDAPI_ARCHIVE} > archives/${HIDAPI_ARCHIVE}
fi

# In MacOSX, we need to replace the dynamic library ID to be able to find
# from OpenOCD executable in installed place.

preinstall_lib()
{
    name=`otool -D $1 | tail -n +2`
    newname=${name/${DISTDIR}/@executable_path/..}
    install_name_tool -id $newname $1
}

install_libusb()
{
    rm -rf libusb
    mkdir libusb
    tar jxf archives/${LIBUSB_ARCHIVE} --strip-components=1 -C libusb

    cd libusb
    ./configure --prefix=${DISTDIR} ${CROSS_COMPILE} || exit 1
    make || exit 1

    if [ "${PLATFORM}" = "Darwin" ]; then
        preinstall_lib libusb/.libs/libusb-1.0.0.dylib
    fi

    make install || exit 1
    cd -
}

install_hidapi()
{
    rm -rf hidapi
    mkdir hidapi
    tar zxf archives/${HIDAPI_ARCHIVE} --strip-components=1 -C hidapi

    cd hidapi
    if [ "${PLATFORM}" = "Darwin" ]; then
        patch -p1 < ../hidapi-00-configure.patch
    fi
    ./bootstrap || exit 1
    PKG_CONFIG_PATH=${DISTDIR}/lib/pkgconfig \
	./configure --prefix=${DISTDIR} ${CROSS_COMPILE} || exit 1
    make || exit 1

    if [ "${PLATFORM}" = "Darwin" ]; then
	    preinstall_lib mac/.libs/libhidapi.0.dylib
    fi

    make install || exit 1
    cd -
}

install_openocd()
{
    cd $OPENOCDDIR

    git clean -xdf
    git -C jimtcl clean -xdf

    ./bootstrap || exit 1
    LDFLAGS='-Wl,-rpath -Wl,"\$\$$ORIGIN/../lib"' \
    PKG_CONFIG_PATH=${DISTDIR}/lib/pkgconfig \
        ./configure --prefix=${DISTDIR} ${CROSS_COMPILE} ${OPENOCD_CONFIGOPTS} || exit 1

    make clean
    make || exit 1
    make install || exit 1

    cd -
}

# Build and install openocd and libraries into temporary directory.

install_libusb
install_hidapi
install_openocd

# Get latest commit date for use package name

cd $OPENOCDDIR
LATEST_DATE=`git show --format=format:%ci -s | cut -f 1 -d ' ' | sed -e 's/-//g'`

if [ -e configure ]; then
    # Get version from configure script
    eval `grep PACKAGE_VERSION= configure`
    OPENOCD_VERSION=$PACKAGE_VERSION
fi
echo OpenOCD Version: $OPENOCD_VERSION
cd -

# Create release archive

mkdir -p dist
package=openocd-${OPENOCD_VERSION}-${OPENOCD_MODVERSION}-${LATEST_DATE}

rm -rf ${package}
mv ${DISTDIR} ${package}

if [ "$TARGET" = "win32" -o "$TARGET" = "win64" ]; then
    distfile=${package}-${TARGET}.zip
    zip -r dist/${distfile} ${package}
else
    distfile=${package}-${TARGET}.tar.bz2
    tar cvjf dist/${distfile} ${package}
fi

(cd dist; shasum -a 256 ${distfile} > ${distfile}.sha)

rm -rf ${package}
