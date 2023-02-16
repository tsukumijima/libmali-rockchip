#!/bin/sh

cd "$(dirname "$0")/.."

# Check for dependencies
./scripts/normalize_dependencies.sh || exit 1

SONAME=libmali.so.1
LIBS=$(find optimize_*/ -name "*.so")

for lib in $LIBS; do
	DEPS=$(readelf -d $lib)

	# Hack out-dated deps
	for dep in libffi.so libcrypto.so; do
		DEP=$(echo $DEPS | grep -oE "$dep.[0-9]*")
		[ -z "$DEP" ] || patchelf $lib --replace-needed $DEP $dep
	done

	# Set a common soname
	echo $DEPS | grep -q "Library soname: \[$SONAME\]" ||
		patchelf --set-soname $SONAME $lib

	# Increase .dynsym's sh_info to workaround local symbol warning:
	# 'found local symbol in global part of symbol table'
	#
	# depends on lief (pip3 install lief)
	readelf -s $lib 2>&1 | grep -wq Warning && \
		scripts/fixup_dynsym.py $lib&
done

wait

for lib in $LIBS; do
	# Normalize library name
	mv $lib "${lib%/*}/$(scripts/parse_name.sh --format $lib)" 2>/dev/null
done

# Update debian control and rules
scripts/update_debian.sh
