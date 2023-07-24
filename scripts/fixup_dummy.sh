#!/bin/sh -e

[ $# -lt 2 ] && {
	echo "usage: $0 <dest dir> <source library>"
	exit 1
}

DEST_DIR="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1"
SOURCE="$(basename $2)"

# Replace dummy library
cd "$DEST_DIR"
cp $SOURCE libmali.so
cp -a libmali.so $SOURCE

if [ -f libMali.so ]; then
	cp -a libmali.so libMali.so
fi

exit 0
