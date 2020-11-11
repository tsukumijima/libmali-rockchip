#!/bin/sh

# Remove fbdev libs
rm -f $(find . -name "*fbdev*.so")

# Link x11 libs
X11_LIBS=$(find . -name "*.so"|grep -vE "gbm.so|wayland.so|x11.so|only-cl.so|dummy.so")
for lib in $X11_LIBS;do
	mv $lib ${lib%.so}-x11.so 2>/dev/null
done
for lib in $(find . -name "*.so"|grep x11.so);do
	ln -sf ${lib##*/} ${lib%-x11.so}.so
done

# Hack out-dated deps
for file in $(find . -type f);do
	patchelf $file --replace-needed libffi.so.6 libffi.so
	patchelf $file --replace-needed libcrypto.so.1.0.0 libcrypto.so
done 2>/dev/null

# TODO: Remove this hack when we have real soname.
for lib in $(find . -name "*.so");do
       patchelf --set-soname libmali.so.1 $lib
done
