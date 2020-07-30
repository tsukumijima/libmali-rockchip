#!/bin/sh

# Generate targets
find lib -type f | sed 's,^lib/,,' > debian/targets
TARGETS=$(cat debian/targets)

# Gather packages and generate install/postinst/prerm files
unset packages
rm debian/*.postinst
rm debian/*.prerm
rm debian/*.install
for target in $TARGETS; do
	export arch=${target%%-*}
	export $(./parse_name.sh $target)
	export package=$name-$arch
	export packages="$packages $package"

	ln -sf postinst debian/$package.postinst
	ln -sf prerm debian/$package.prerm

	echo "$package/usr/lib/*/* usr/lib/mali/" > debian/$package.install

	# TODO: Remove this hack when we have real soname.
	echo "$package/usr/lib/libmali.so.1 /usr/lib/" >> debian/$package.install

	echo $gpu | grep -q utgard && continue
	[ "$subversion" = 'without-cl' ] && continue

	echo "$package/etc/* etc/" >> debian/$package.install
done

# Generate control
cp debian/control.in debian/control
for target in $TARGETS; do
	export arch=${target%%-*}
	export $(./parse_name.sh $target)
	export package=$name-$arch
	export conflicts="$(echo $packages | sed "s/ *$package */ /")"

	echo
	echo "Package: $package"
	if [ $arch = 'arm' ]; then
		echo "Architecture: armhf"
	else
		echo "Architecture: arm64"
	fi
	echo "Multi-Arch: same"
	echo -n "Conflicts: "
	echo $conflicts | sed "s/ /, /g"
	echo "Depends: \${shlibs:Depends}, \${misc:Depends}"
	echo "Description: Mali GPU User-Space Binary Drivers"
done >> debian/control
