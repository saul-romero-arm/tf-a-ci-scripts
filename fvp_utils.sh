#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -u

bl1_addr="${bl1_addr:-0x0}"
bl31_addr="${bl31_addr:-0x04020000}"
bl32_addr="${bl32_addr:-0x04002000}"
bl33_addr="${bl33_addr:-0x88000000}"
dtb_addr="${dtb_addr:-0x82000000}"
fip_addr="${fip_addr:-0x08000000}"
initrd_addr="${initrd_addr:-0x84000000}"
kernel_addr="${kernel_addr:-0x80080000}"
el3_payload_addr="${el3_payload_addr:-0x80000000}"

ns_bl1u_addr="${ns_bl1u_addr:-0x0beb8000}"
fwu_fip_addr="${fwu_fip_addr:-0x08400000}"
backup_fip_addr="${backup_fip_addr:-0x09000000}"
romlib_addr="${romlib_addr:-0x03ff2000}"

uboot32_fip_url="$linaro_release/fvp32-latest-busybox-uboot/fip.bin"

rootfs_url="$linaro_release/lt-vexpress64-openembedded_minimal-armv8-gcc-4.9_20150912-729.img.gz"

# FVP Kernel URLs
declare -A fvp_kernels
fvp_kernels=(
[fvp-aarch32-zimage]="$linaro_release/fvp32-latest-busybox-uboot/Image"
[fvp-busybox-uboot]="$linaro_release/fvp-latest-busybox-uboot/Image"
[fvp-oe-uboot32]="$linaro_release/fvp32-latest-oe-uboot/Image"
[fvp-oe-uboot]="$linaro_release/fvp-latest-oe-uboot/Image"
[fvp-quad-busybox-uboot]="$tfa_downloads/quad_cluster/Image"
)

# From Linaro 16.12 release onwards the prebuilt ramdisk.img
# contains 32-bit binaries which fails to boot on a AArch64-only
# system.
#
# An updated 64-bit only ramdisk.img, which has been manually built,
# has replaced the prebuilt version.
#
# When updating to a future Linaro release if this issue has not
# been resolved then the fvp-uboot-tspd-aarch64-only run-config will
# fail.

# FVP initrd URLs
declare -A fvp_initrd_urls
fvp_initrd_urls=(
[aarch32-ramdisk]="$linaro_release/fvp32-latest-busybox-uboot/ramdisk.img"
[aarch64-only-ramdisk]="$linaro_release/fvp-latest-busybox-uboot/ramdisk-aarch64.img"
[dummy-ramdisk]="$linaro_release/fvp-latest-oe-uboot/ramdisk.img"
[dummy-ramdisk32]="$linaro_release/fvp32-latest-oe-uboot/ramdisk.img"
[default]="$linaro_release/fvp-latest-busybox-uboot/ramdisk.img"
)

# FIXME use optee pre-built binaries
get_optee_bin() {
	url="$jenkins_url/job/tf-optee-build/PLATFORM_FLAVOR=fvp,label=arch-dev/lastSuccessfulBuild/artifact/artefacts/tee.bin" \
		saveas="bl32.bin" fetch_file
	archive_file "bl32.bin"
}

get_uboot32_bin() {
	local tmpdir="$(mktempdir)"

	pushd "$tmpdir"
	extract_fip "$uboot32_fip_url"
	mv "nt-fw.bin" "uboot.bin"
	archive_file "uboot.bin"
	popd
}

get_uboot_bin() {
	local uboot_url="$linaro_release/fvp-latest-busybox-uboot/bl33-uboot.bin"

	url="$uboot_url" saveas="uboot.bin" fetch_file
	archive_file "uboot.bin"
}

get_uefi_bin() {

	local project_scratch=/arm/projectscratch/ssg/uefi

	local uefi_build_type="${uefi_build_type:-DEBUG}"
	local uefi_build_aarch="${uefi_build_aarch:-AARCH64}"
	local uefi_build_toolchain="${uefi_build_toolchain:-GCC5}"
	local uefi_build_jobname="${uefi_build_jobname:-uefi-woa-github-edk2-master-ci}"
	local uefi_tables="${uefi_tables:-static}"

	uefi_ci_bin=FVP_${uefi_build_aarch}_EFI.fd
	uefi_build_conf=fvp/${uefi_build_type}_${uefi_build_toolchain}/$uefi_build_aarch

	if [ -d $project_scratch ]; then
		uefi_artifacts_root=$project_scratch/$uefi_tables/Artifacts
	else
		local uefi_ci_job_url="$jenkins_url/job/uefi/job/$uefi_build_jobname"

		local uefi_ci_conf="BUILD_AARCH=$uefi_build_aarch"
		uefi_ci_conf="${uefi_ci_conf},BUILD_TYPE=${uefi_build_type}"
		uefi_ci_conf="${uefi_ci_conf},EDK2_BUILD_PLATFORM=fvp"
		uefi_ci_conf="${uefi_ci_conf},label=arch-dev"

		local artifacts=lastSuccessfulBuild/artifact/Artifacts
		uefi_artifacts_root=$uefi_ci_job_url/$uefi_ci_conf/$artifacts

	fi

	uefi_ci_bin_url=$uefi_artifacts_root/$uefi_build_conf/$uefi_ci_bin

	url=$uefi_ci_bin_url saveas="uefi.bin" fetch_file
	archive_file "uefi.bin"
}

get_kernel() {
	local kernel_type="${kernel_type:?}"
	local url="${fvp_kernels[$kernel_type]}"

	url="${url:?}" saveas="kernel.bin" fetch_file
	archive_file "kernel.bin"
}

get_initrd() {
	local initrd_type="${initrd_type:?}"
	local url="${fvp_initrd_urls[$initrd_type]}"

	url="${url:?}" saveas="initrd.bin" fetch_file
	archive_file "initrd.bin"
}

get_dtb() {
	local dtb_type="${dtb_type:?}"
	local dtb_url
	local dtb_saveas="$workspace/dtb.bin"

	case "$dtb_type" in
		"fvp-base-quad-cluster-gicv3-psci")
			# Get the quad-cluster FDT from pdsw area
			dtb_url="$tfa_downloads/quad_cluster/fvp-base-quad-cluster-gicv3-psci.dtb"
			url="$dtb_url" saveas="$dtb_saveas" fetch_file
			;;
		"sgm775")
			# Get the SGM775 FDT from pdsw area
			dtb_url="$sgm_prebuilts/sgm775.dtb"
			url="$dtb_url" saveas="$dtb_saveas" fetch_file
			;;
		*)
			# Generate DTB file from DTC
			dtc -I dts -O dtb \
				"$tf_root/fdts/${dtb_type}.dts" -o "$dtb_saveas"
	esac

	archive_file "$dtb_saveas"
}

get_rootfs() {
	local tmpdir
	local fs_base="$(echo $(basename $rootfs_url) | sed 's/\.gz$//')"
	local cached="$project_filer/ci-files/$fs_base"

	if upon "$jenkins_run" && [ -f "$cached" ]; then
		# Job workspace is limited in size, and the root file system is
		# quite large. This means, parallel runs of root file system
		# tests could fail. So, for Jenkins runs, copy and use the root
		# file system image from the $CI_SCRATCH location
		local private="$CI_SCRATCH/$JOB_NAME-$BUILD_NUMBER"
		mkdir -p "$private"
		rm -f "$private/rootfs.bin"
		url="$cached" saveas="$private/rootfs.bin" fetch_file
		ln -s "$private/rootfs.bin" "$archive/rootfs.bin"
		return
	fi

	tmpdir="$(mktempdir)"
	pushd "$tmpdir"
	url="$rootfs_url" saveas="rootfs.bin" fetch_file

	# Possibly, the filesystem image we just downloaded is compressed.
	# Decompress it if required.
	if file "rootfs.bin" | grep -iq 'gzip compressed data'; then
		echo "Decompressing root file system image rootfs.bin ..."
		gunzip --stdout "rootfs.bin" > uncompressed_fs.bin
		mv uncompressed_fs.bin "rootfs.bin"
	fi

	archive_file "rootfs.bin"
	popd
}

fvp_romlib_runtime() {
	local tmpdir="$(mktempdir)"

	# Save BL1 and romlib binaries from original build
	mv "${tf_build_root:?}/${plat:?}/${mode:?}/romlib/romlib.bin" "$tmpdir/romlib.bin"
	mv "${tf_build_root:?}/${plat:?}/${mode:?}/bl1.bin" "$tmpdir/bl1.bin"

	# Patch index file
	cp "${tf_root:?}/plat/arm/board/fvp/jmptbl.i" "$tmpdir/jmptbl.i"
	sed -i '/rom_lib_init/! s/.$/&\ patch/' ${tf_root:?}/plat/arm/board/fvp/jmptbl.i

	# Rebuild with patched file
	echo "Building patched romlib:"
	build_tf

	# Restore original index
	mv "$tmpdir/jmptbl.i" "${tf_root:?}/plat/arm/board/fvp/jmptbl.i"

	# Retrieve original BL1 and romlib binaries
	mv "$tmpdir/romlib.bin" "${tf_build_root:?}/${plat:?}/${mode:?}/romlib/romlib.bin"
	mv "$tmpdir/bl1.bin" "${tf_build_root:?}/${plat:?}/${mode:?}/bl1.bin"
}

set +u
