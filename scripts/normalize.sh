#!/bin/sh

SONAME=libmali.so.1
LIBS=$(find optimize_*/ -name "*.so")

for lib in $LIBS; do
	DEPS=$(readelf -d $lib)

	# Hack out-dated deps
	for dep in libffi.so.6 libcrypto.so.1.0.0; do
		echo $DEPS | grep -wq $dep &&
			patchelf $lib --replace-needed $dep ${dep%.so*}.so
	done

	# Set a common soname
	echo $DEPS | grep -q "Library soname: \[$SONAME\]" ||
		patchelf --set-soname $SONAME $lib

	# Increase .dynsym's sh_info to workaround local symbol warning:
	# 'found local symbol in global part of symbol table'
	#
	# depends on lief (pip3 install lief)
	readelf -s $lib 2>&1 | grep -q Warning && \
		scripts/fixup_dynsym.py $lib&

	# Rename default libs to -x11
	echo $lib | grep -qE "\-[rg].p.\.so" || continue
	[ ! -L $lib ] && mv $lib ${lib%.so}-x11.so
	rm $lib
done

# Update debian control and rules
scripts/update_debian.sh

wait
