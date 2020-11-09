#!/bin/sh

# Generate targets and packages
find lib -type f | sed 's,^lib/,,' > debian/targets
TARGETS=$(cat debian/targets)
PACKAGES=$(cat debian/targets | sed "s/.*\(libmali.*\).so/\1/" | sort | uniq)

rm -f debian/*.postinst
rm -f debian/*.prerm
rm -f debian/*.install
rm -f control.*

# NOTE: Assuming multiarch packages could share debian files
for target in $TARGETS; do
	export $(./parse_name.sh $target)
	package=$name
	control=control.$package

	if echo $target | grep -q aarch64; then
		arch=arm64
	else
		arch=armhf
	fi

	# Handle multiarch packages
	if [ -e $control ]; then
		sed -i "s/\(Architecture:\).*/\1 armhf arm64/" $control
		continue
	fi

	# Generate control files
	conflicts="$(echo $PACKAGES | xargs -n 1 | grep -v "$package$")"
	cat << EOF > $control

Package: $package
Architecture: $arch
Conflicts: $(echo $conflicts | sed "s/ /, /g")
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: Mali GPU User-Space Binary Drivers
EOF

	# Generate install/postinst/prerm files
	ln -sf postinst debian/$package.postinst
	ln -sf prerm debian/$package.prerm

	echo "$package/usr/lib/*/* usr/lib/mali/" > debian/$package.install

	# TODO: Remove this hack when we have real soname.
	echo "$package/usr/lib/libmali.so.1 /usr/lib/" >> debian/$package.install

	grep -q clCreateContext lib/$target || continue

	echo "$package/etc/* etc/" >> debian/$package.install
done

# Generate control
cat debian/control.in control.* > debian/control
rm -f control.*
