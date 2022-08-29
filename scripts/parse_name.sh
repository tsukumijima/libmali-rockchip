#!/bin/sh

PRINT_GPU=false
PRINT_VERSION=false
PRINT_SUBVERSION=false
PRINT_PLATFORM=false
PRINT_FORMAT=false

PLATFORMS="only-cl|without-cl|vulkan|dummy|x11|wayland|gbm"

# Normalize platform variable
normalize_platform() {
	PLATFORM="$@"
	for platform in $(echo $PLATFORMS|xargs -d'|'); do
		echo $PLATFORM|grep -ow $platform|uniq
	done
}

parse_name() {
	FILE="$@"
	LIB=${FILE##*/}
	LIB=${LIB%.so}

	[ -z "$LIB" ] && return

	GPU=$(echo $LIB|cut -sd'-' -f'2,3')
	VERSION=$(echo $LIB|cut -sd'-' -f4)

	PLATFORM=$(echo $LIB|grep -owE "$PLATFORMS"|paste -sd'-')
	[ -z "$PLATFORM" ] && PLATFORM=x11

	SUBVERSION=$(echo ${LIB%-$PLATFORM}|cut -sd'-' -f'5-')

	# Fixup GBM platform
	if readelf -s "$FILE" 2>/dev/null | grep -wq gbm_create_device; then
		PLATFORM=${PLATFORM}-gbm
	fi
	PLATFORM=$(normalize_platform $PLATFORM|paste -sd'-')

	if $PRINT_GPU;then
		echo $GPU
	elif $PRINT_VERSION;then
		echo $VERSION
	elif $PRINT_SUBVERSION;then
		echo $SUBVERSION
	elif $PRINT_PLATFORM;then
		echo $PLATFORM
	elif $PRINT_FORMAT;then
		echo libmali-$GPU-$VERSION${SUBVERSION:+-$SUBVERSION}-$PLATFORM.so
	else
		echo name=$LIB
		echo gpu=$GPU
		echo version=$VERSION
		echo subversion=$SUBVERSION
		echo platform=$PLATFORM
	fi
}

case "$1" in
	--gpu)
		PRINT_GPU=true
		shift
		;;
	--version)
		PRINT_VERSION=true
		shift
		;;
	--subversion)
		PRINT_SUBVERSION=true
		shift
		;;
	--platform)
		PRINT_PLATFORM=true
		shift
		;;
	--format)
		PRINT_FORMAT=true
		shift
		;;
esac

for lib in "$@";do
	parse_name $lib
done

exit 0
