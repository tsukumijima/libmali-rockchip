#!/bin/sh -e

[ $# -lt 1 ] && {
	echo "usage: $0 <path of include>"
	exit 1
}

HEADER="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1/EGL/eglplatform.h"

[ -f "$HEADER" ] && \
	sed -i 's/MESA_EGL_NO_X11_HEADERS/__unix__/g' "$HEADER"

exit 0
