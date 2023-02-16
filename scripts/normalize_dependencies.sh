#!/bin/bash

# We require lief
if ! python3 -c "import lief"; then
	echo -e "\e[35mNeeds lief:\e[0m"
	echo "pip3 install lief"
fi

# We require patchelf >= 0.10 for this fix:
# https://github.com/NixOS/patchelf/pull/117

major_min=0
minor_min=10

version=$(patchelf --version 2>&1 | cut -d' ' -f2 || echo 0)
major=$(echo "$version" | cut -d. -f1)
minor=$(echo "$version" | cut -d. -f2)

if [ $major -gt $major_min ]; then
	exit 0
fi

if [ $major -eq $major_min -a $minor -ge $minor_min ]; then
	exit 0
fi

echo -e "\e[35mNeeds patchelf >= 0.10:\e[0m"
echo "git clone https://github.com/NixOS/patchelf.git"
echo "cd patchelf"
echo "git checkout 0.10"
echo "./bootstrap.sh"
echo "./configure"
echo "make -j8"
echo "install -m 0755 src/patchelf /usr/local/bin/patchelf"
exit 1
