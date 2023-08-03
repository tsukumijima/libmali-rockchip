#!/bin/sh -e

[ $# -lt 2 ] && {
	echo "usage: $0 <path of include> <cl version>"
	exit 1
}

HEADER="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1/CL/cl_version.h"

if [ -f "$HEADER" ]; then
	VER="$2"
	TARGET_VER=$(echo "$VER * 100" | bc | sed "s/\.0$//")

	sed -i -e "s/\(Defaulting to \).* ([^)]*/\1$TARGET_VER (OpenCL $VER/" \
		-e "s/\(^#define CL_TARGET_OPENCL_VERSION \).*/\1$TARGET_VER/" \
		"$HEADER"
fi

exit 0
