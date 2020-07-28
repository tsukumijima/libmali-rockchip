#!/bin/sh

ARCH=${1:-aarch64}
GPU=${2:-midgard-t86x}
VERSION=${3:-r18p0}
SUBVERSION=${4:-none}
PLATFORM=${5:-x11}

[ ${ARCH} = 'armv7l' -o ${ARCH} = 'armhf' -o ${ARCH} = 'arm32' ] && ARCH=arm
[ ${ARCH} = 'armv8' -o ${ARCH} = 'arm64' ] && ARCH=aarch64

if [ ${SUBVERSION} = 'none' ]; then
	LIB="libmali-${GPU}-${VERSION}-${PLATFORM}.so"
elif [ ${SUBVERSION} = 'all' ]; then
	LIB="libmali-${GPU}-${VERSION}*-${PLATFORM}.so"
else
	LIB="libmali-${GPU}-${VERSION}-${SUBVERSION}-${PLATFORM}.so"
fi

find lib/${ARCH}* -name ${LIB} 2>/dev/null
