#!/bin/sh

PRINT_GPU=false
PRINT_VERSION=false
PRINT_SUBVERSION=false
PRINT_PLATFORM=false

PLATFORMS="gbm|wayland|x11|only-cl|dummy"

parse_name() {
	[ -z "$1" ] && return

	GPU=$(echo $1|cut -d'-' -f'2,3')
	VERSION=$(echo $1|cut -d'-' -f4)

	PLATFORM=$(echo $1|grep -owE "$PLATFORMS"|xargs -n 1|tail -1)
	[ -z "$PLATFORM" ] && PLATFORM=x11

	SUBVERSION=$(echo ${1%-$PLATFORM}|cut -d'-' -f'5-')

	if $PRINT_GPU;then
		echo $GPU
	elif $PRINT_VERSION;then
		echo $VERSION
	elif $PRINT_SUBVERSION;then
		echo $SUBVERSION
	elif $PRINT_PLATFORM;then
		echo $PLATFORM
	else
		echo name=$1
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
esac

for lib in "$@";do
	parse_name $(echo $lib|grep -o "libmali-[^\.]*")
done
