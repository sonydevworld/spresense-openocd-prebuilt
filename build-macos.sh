#!/bin/bash

set -x

LIBUSB_REPOS=https://github.com/libusb/libusb
LIBUSB_VERSION=1.0.21
LIBUSB_ARCHIVE=libusb-${LIBUSB_VERSION}.tar.bz2

HIDAPI_REPOS=https://github.com/libusb/hidapi
HIDAPI_VERSION=0.9.0
HIDAPI_ARCHIVE=hidapi-${HIDAPI_VERSION}.tar.gz

OPENOCD_VERSION=0.10.0
OPENOCD_MODVERSION=spr1

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

if [ ! -d openocd ]; then
    echo "OpenOCD source directory not found. Please clone OpenOCD first!"
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

install_libusb()
{
    rm -rf libusb
    mkdir libusb
    tar jxf archives/${LIBUSB_ARCHIVE} --strip-components=1 -C libusb

    cd libusb
    ./configure --prefix=${DISTDIR} || { echo "configure failed."; exit 2; }
    make && make install
    cd -
}

install_hidapi()
{
    rm -rf hidapi
    mkdir hidapi
    tar zxf archives/${HIDAPI_ARCHIVE} --strip-components=1 -C hidapi

    cd hidapi
    ./bootstrap || { echo "bootstrap failed."; exit 3; }
    ./configure --prefix=${DISTDIR} || { echo "configure failed."; exit 3; }
    make && make install
    cd -
}

install_openocd()
{
    cd openocd

    git clean -xdf
    ./bootstrap || { echo "bootstrap failed."; exit 1; }
    PKG_CONFIG_PATH=${DISTDIR}/lib/pkgconfig \
	./configure --prefix=${DISTDIR} ${OPENOCD_CONFIGOPTS} || { echo "configure failed."; exit 2; }
    make && make install

    cd -
}

# Build and install openocd and libraries into temporary directory.

install_libusb
install_hidapi
install_openocd

# Replace dynamic link library path for redistributable.

if [ "`uname -s`" = "Darwin" ]; then

    OPENOCD=${DISTDIR}/bin/openocd

    libusb_name=`otool -L ${OPENOCD} | grep libusb | cut -f 1 -d ' '`
    hidapi_name=`otool -L ${OPENOCD} | grep hidapi | cut -f 1 -d ' '`

    libusb_newname=${libusb_name/${DISTDIR}/@executable_path/..}
    hidapi_newname=${hidapi_name/${DISTDIR}/@executable_path/..}

    install_name_tool -change ${libusb_name} ${libusb_newname} ${OPENOCD}
    install_name_tool -change ${hidapi_name} ${hidapi_newname} ${OPENOCD}
fi

# Get latest commit date for use package name

cd openocd
LATEST_DATE=`git show --format=format:%ci -s | cut -f 1 -d ' ' | sed -e 's/-//g'`
cd -

# Create release archive

package=openocd-${OPENOCD_VERSION}-${OPENOCD_MODVERSION}-${LATEST_DATE}

rm -rf ${package}
mv ${DISTDIR} ${package}
tar cvjf ${package}-macosx.tar.bz2 ${package}
ls -l ${package}-macosx.tar.bz2
rm -rf ${package}
