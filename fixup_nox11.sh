#!/bin/sh -e

[ $# -lt 1 ] && {
	echo "usage: $0 <path of eglplatform.h>"
	exit 1
}

HEADER="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1"

sed -i 's/MESA_EGL_NO_X11_HEADERS/__unix__/g' "$HEADER"
