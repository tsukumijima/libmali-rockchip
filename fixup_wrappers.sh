#!/bin/sh -e

[ $# -lt 1 ] && {
	echo "usage: $0 <dest dir>"
	exit 1
}

BUILD_DIR="${MESON_BUILD_ROOT:-build}"
DEST_DIR="${MESON_INSTALL_DESTDIR_PREFIX:-/usr}/$1"

# Cleanup wrappers
cd "$DEST_DIR"
for f in $(cd $BUILD_DIR && find . -maxdepth 1 -type f -name "lib*"); do
	echo $f | grep -q libmali.so || cp -a libmali.so $f
done
