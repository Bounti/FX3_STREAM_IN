#!/usr/bin/env bash

#
# Copyright (C) Telecom ParisTech
# Copyright (C) Renaud Pacalet (renaud.pacalet@telecom-paristech.fr)
# 
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
#

version=0.1
packages=/packages/LabSoC
downloads=/opt/downloads
builds=/opt/builds
toolchain=arm-unknown-linux-gnueabihf
sab4z=$(realpath $(dirname $(realpath $0))/..)


usage="
usage: $( basename $0 ) [options] BOARD

OPTIONS (default)
	-s, --sab4z SAB4Z ($sab4z)
		Path of SAB4Z clone

	-p, --packages PACKAGES ($packages)
		Path of directory in which buildroot, linux-xlnx, u-boot-xlnx and device-tree-xlnx clones are to be found

	-d, --downloads DOWNLOADS ($downloads)
		Path of directory where to download packages

	-b, --builds BUILDS ($builds)
		Path of directory where to build things

	-t, --toolchain TOOLCHAIN ($toolchain)
		Prefix of toolchain (whithout trailing -)

	-h, --help
		Display help text and exit

	-v, --version
		Display version and exit

BOARD
	zybo, zed and zc706 are the only currently supported boards
"

TEMP=$( getopt --options s:p:d:b:t:hv \
	--longoptions sab4z:,packages:,downloads:,builds:,toolchain:,help,version \
	--name $0 -- "$@" )

if [ $? != 0 ]; then
	echo "*** Invalid arguments" >&2
	echo "$usage" >&2
	exit 1
fi

eval set -- "$TEMP"

while true ; do
	case "$1" in
		-s|--sab4z) sab4z=$2; shift 2;;
		-p|--packages) packages=$2; shift 2;;
		-d|--downloads) downloads=$2; shift 2;;
		-b|--builds) builds=$2; shift 2;;
		-t|--toolchain) toolchain=$2; shift 2;;
		-h|--help) echo "$usage"; exit 0;;
		-v|--version) echo "$version"; exit 0;;
		--) shift; break;;
		*) echo "*** Invalid option"; exit 1;;
	esac
done

if [[ $# -ne 1 ]]; then
	echo "*** No board specified" >&2
	echo "$usage" >&2
	exit 1
fi
board="$1"
if [[ "$board" != "zybo" && "$board" != "zed" && "$board" != "zc706" ]]; then
	echo "*** Unknown board" >&2
	echo "$usage" >&2
	exit 1
fi

toolchainpath=$(which ${toolchain}-gcc)
if [[ $? -ne 0 ]]; then
	echo "*** Toolchain $toolchain not found" >&2
	echo "$usage" >&2
	exit 1
fi
toolchainpath=$(dirname $(realpath $toolchainpath))

echo "sab4z         = $sab4z"
echo "packages      = $packages"
echo "downloads     = $downloads"
echo "builds        = $builds"
echo "toolchain     = $toolchain"
echo "toolchainpath = $toolchainpath"
echo "board         = $board"

toolchainpath=$(dirname $toolchainpath)
buildroot=$packages/buildroot
linux=$packages/linux-xlnx
uboot=$packages/u-boot-xlnx
dts=$packages/device-tree-xlnx

# Sdcard archive
s=$builds/$board/sdcard
mkdir -p $s

# Bitstream
v=$builds/$board/vv
if [ -d $v ]; then
	echo "*** $v already exists. Skipping..." >&2
else
	echo "Generating bitstream ($builds/$board/vv/top.runs/impl_1/top_wrapper.bit)..."
	mkdir -p $v
	make -C $sab4z VVBUILD=$v VVBOARD=$board vv-all
fi

# Device tree
d=$builds/$board/dts
if [ -d $d ]; then
	echo "*** $d already exists. Skipping..." >&2
else
	echo "Generating device tree sources ($d/)..."
	make -C $sab4z VVBUILD=$v XDTS=$dts DTSBUILD=$d dts
	echo "Compiling device tree blob ($s/devicetree.dtb)..."
	dtc -I dts -O dtb -o $s/devicetree.dtb $d/system.dts
fi

# FSBL
f=$builds/$board/fsbl
if [ -d $f ]; then
	echo "*** $f already exists. Skipping..." >&2
else
	echo "Generating FSBL sources ($f/)..."
	mkdir -p $f
	make -C $sab4z VVBUILD=$v FSBLBUILD=$f fsbl
	echo "Compiling FSBL ($f/executable.elf)..."
	make -C $f
fi

# Root filesystem
b=$builds/rootfs
path=$PATH
export PATH=/usr/bin:/bin:$toolchainpath
if [ -d $b ]; then
	echo "*** $b already exists. Skipping configuration..." >&2
else
	echo "Configuring root filesystem ($b)..."
	mkdir -p $b
	touch $b/external.mk $b/Config.in
	echo 'name: sab4z' > $b/external.desc
	echo 'desc: sab4z system with buildroot' >> $b/external.desc
	mkdir -p $b/configs $b/overlays/etc/profile.d $b/overlays/root/.ssh $b/overlays/etc/dropbear
	echo "export PS1='Sab4z> '" > $b/overlays/etc/profile.d/prompt.sh
	cp $sab4z/scripts/sab4z_rsa.pub $b/overlays/root/.ssh/authorized_keys
	cp $sab4z/scripts/dropbear_ecdsa_host_key $b/overlays/etc/dropbear
	cp $sab4z/scripts/buildroot_defconfig $b/configs
	echo "BR2_DL_DIR=\"$downloads/buildroot-src\"" >> $b/configs/buildroot_defconfig
	echo "BR2_TOOLCHAIN_EXTERNAL_PATH=\"$toolchainpath\"" >> $b/configs/buildroot_defconfig
	echo "BR2_TOOLCHAIN_EXTERNAL_CUSTOM_PREFIX=\"$toolchain\"" >> $b/configs/buildroot_defconfig
	echo "BR2_CCACHE_DIR=\"$builds/buildroot-ccache\"" >> $b/configs/buildroot_defconfig
	echo "CONFIG_RX=y" > $b/configs/busybox_defconfig
	make -C $buildroot BR2_EXTERNAL=$b O=$b buildroot_defconfig
fi
echo "Building software applications ($sab4z/C/)..."
make -C $sab4z/C CFLAGS=-g clean hello_world sab4z
echo "Copying software application in root filesystem ($b/overlays/root/)..."
cp $sab4z/C/hello_world $sab4z/C/sab4z $b/overlays/root
echo "Building root filesystem ($b/images/rootfs.cpio.uboot)..."
make -C $b
export PATH=$path

export PATH=$PATH:$b/host/usr/bin
export CROSS_COMPILE=${toolchain}-

# Linux kernel and modules
k=$builds/kernel
if [ -d $k ]; then
	echo "*** $k already exists. Skipping configuration..." >&2
else
	echo "Configuring Linux kernel ($k)..."
	mkdir -p $k
	make -C $linux O=$k ARCH=arm xilinx_zynq_defconfig
fi
echo "Building Linux kernel ($k/arch/arm/boot/uImage)..."
make -C $k -j24 ARCH=arm
make -C $k ARCH=arm LOADADDR=0x8000 uImage
echo "Copying Linux kernel ($s/uImage)..."
cp $k/arch/arm/boot/uImage $s
echo "Building and installing Linux kernel modules ($b/overlays)..."
make -C $k -j24 ARCH=arm modules
make -C $k ARCH=arm modules_install INSTALL_MOD_PATH=$b/overlays
path=$PATH
export PATH=/usr/bin:/bin:$toolchainpath
make -C $b
export PATH=$path
echo "Copying root filesystem ($s/uramdisk.image.gz)..."
cp $b/images/rootfs.cpio.uboot $s/uramdisk.image.gz

# U-Boot
u=$builds/$board/uboot
if [ -d $u ]; then
	echo "*** $u already exists. Skipping configuration..." >&2
else
	echo "Configuring U-Boot ($u)..."
	mkdir -p $u
	make -C $uboot O=$u zynq_${board}_defconfig
fi
echo "Building U-Boot ($u/u-boot.elf)..."
make -C $u -j24
cp $u/u-boot $u/u-boot.elf

# Boot image
echo "Generating boot image ($builds/$board/sdcard/boot.bin)..."
cd $builds/$board
bootgen -w -image $sab4z/scripts/boot.bif -o $builds/$board/sdcard/boot.bin
