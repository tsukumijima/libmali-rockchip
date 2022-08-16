#!/bin/sh


# Generate targets
TARGETS=$(echo ${@:-$(find lib -type f)} | xargs -n 1 | sed 's,^lib/,,' | sort)
echo $TARGETS | xargs -n 1 > debian/targets

rm -f control.*

# NOTE: Assuming multiarch packages could share debian files
for target in $TARGETS; do
	#export $(scripts/parse_name.sh $target)
	#package=$name
	package=$(basename ${target%.so})
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

	cat << EOF > $control

Package: $package
Architecture: $arch
Provides: libmali
Conflicts: libmali
Replaces: libmali
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: Mali GPU User-Space Binary Drivers
EOF
done

# Generate control
cat debian/control.in control.* > debian/control
rm -f control.*
