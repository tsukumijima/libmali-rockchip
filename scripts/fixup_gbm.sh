#!/bin/sh -e

[ $# -lt 1 ] && {
	echo "usage: $0 <path of include>"
	exit 1
}

HEADER="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1/gbm.h"

if [ -f "$HEADER" ]; then
	sed -i -e '$i /* HACK: Mali does not support these flag */' \
		-e '$i #define GBM_BO_USE_LINEAR 0' \
		-e '$i #define GBM_BO_USE_PROTECTED 0' \
		-e '$i #define GBM_BO_USE_FRONT_RENDERING 0\n' "$HEADER"
fi

exit 0
