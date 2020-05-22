#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -u

#arm_fpga Kernel URLs
declare -A arm_fpga_kernels
arm_fpga_kernels=(
[test-kernel-aarch64]="$tfa_downloads/arm-fpga/kernel-image"
)

#arm_fpga dtbs
declare -A arm_fpga_dtbs
arm_fpga_dtbs=(
[zeus-dtb]="$tfa_downloads/arm-fpga/zeus.dtb"
[hera-dtb]="$tfa_downloads/arm-fpga/hera.dtb"
)

#arm_fpga initramfs
declare -A arm_fpga_initramfs
arm_fpga_initramfs=(
[busybox.initrd]="$tfa_downloads/arm-fpga/busybox.initrd"
)

get_kernel() {
	local kernel_type="${kernel_type:?}"
	local url="${arm_fpga_kernels[$kernel_type]}"
	local kernel_saveas="kernel.bin"

	url="${url:?}" saveas="${kernel_saveas:?}" fetch_file
	archive_file "$kernel_saveas"
}

get_dtb() {
	local dtb_type="${dtb_type:?}"
	local dtb_url="${arm_fpga_dtbs[$dtb_type]}"
	local dtb_saveas="dtb.bin"

	url="${dtb_url:?}"  saveas="${dtb_saveas:?}" fetch_file
	archive_file "$dtb_saveas"
}

get_initrd() {
	local initrd_type="${initrd_type:?}"
	local url="${arm_fpga_initramfs[$initrd_type]}"
	local initrd_saveas="initrd.bin"

	url="${url:?}" saveas="${initrd_saveas:?}" fetch_file
	archive_file "$initrd_saveas"
}

get_linkerscript() {
	local url="$tfa_downloads/arm-fpga/model.lds"
	local ld_saveas="linker.ld"
	local artefacts_dir="${fullpath:?}"

	url="${url:?}" saveas="${ld_saveas:?}" fetch_file
	sed -i "s+<artefacts>+"$artefacts_dir"+g" $ld_saveas
	archive_file "$ld_saveas"
}

link_fpga_images(){
	local arch="${arch:-aarch64elf}"
	local ld_file="${ld_file:-linker.ld}"
	local out="${out:-image.elf}"
	local cross_compile="${nfs_volume}/pdsw/tools/gcc-linaro-6.2.1-2016.11-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"

	`echo "$cross_compile"ld` -m $arch -T $ld_file -o $out
	archive_file "$out"
}

set +u
