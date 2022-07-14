#!/bin/bash

ARCH=${1:-aarch64}
GPU=${2:-midgard-t86x}
VERSION=${3:-r18p0}
SUBVERSION=${4:-none}
PLATFORM=${5:-gbm}
OPTIMIZE=${6:-O3}

[ ${ARCH} = 'armv7l' -o ${ARCH} = 'armhf' -o ${ARCH} = 'arm32' ] && ARCH=arm
[ ${ARCH} = 'armv8' -o ${ARCH} = 'arm64' ] && ARCH=aarch64

# Normalize platform variable
PLATFORM=$(scripts/parse_name.sh --platform $PLATFORM)

if [ ${SUBVERSION} = 'none' ]; then
	LIB="libmali-${GPU}-${VERSION}-${PLATFORM}"
elif [ ${SUBVERSION} = 'all' ]; then
	LIB="libmali-${GPU}-${VERSION}\(-[rg][0-9]+p[0-9]+\)*-${PLATFORM}"
else
	LIB="libmali-${GPU}-${VERSION}-${SUBVERSION}-${PLATFORM}"
fi

DIR=lib
case ${OPTIMIZE} in
	O*)
		DIR=optimize_${OPTIMIZE#O}
		;;
esac

LIBS=$(find ${DIR}/${ARCH}* -regex ".*${LIB}.so")

if [ -z "$LIBS" ]; then
	LIBS=$(find ${DIR}/${ARCH}* -regex ".*${LIB}-gbm.so")
	[ -n "$LIBS" ] && echo "Fallback to GBM version!" >&2
fi

echo $LIBS

exit 0
