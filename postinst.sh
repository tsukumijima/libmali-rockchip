#!/bin/sh

[ $# -lt 2 ] && exit

LIB_DIR="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1"
LIBMALI="$(basename $2)"

cd $LIB_DIR && \
	cp "$LIBMALI" libmali.so && \
	ln -sf libmali.so "$LIBMALI"
