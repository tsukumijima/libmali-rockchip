#!/bin/sh

# Generate targets and packages
find lib -type f | sed 's,^lib/,,' > debian/targets
TARGETS=$(cat debian/targets)
PACKAGES=$(cat debian/targets | sed "s/.*\(libmali.*\).so/\1/" | sort | uniq)

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
done

# Generate control
cat debian/control.in control.* > debian/control
rm -f control.*
