#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -u

scp_bl2_url="$linaro_release/juno-latest-oe-uboot/SOFTWARE/scp_bl2.bin"
psci_reset2_scp_bl2_url="$tfa_downloads/psci_reset2/scp_bl2.bin"
uboot_bl33_url="$linaro_release/juno-latest-oe-uboot/SOFTWARE/bl33-uboot.bin"
optee_fip_url="$linaro_release/juno-ack-android-uboot/SOFTWARE/fip.bin"

juno_recovery_root="$linaro_release/juno-latest-oe-uboot"

uboot32_fip_url="$linaro_release/juno32-latest-oe-uboot/SOFTWARE/fip.bin"
juno32_recovery_root="$linaro_release/juno32-latest-busybox-uboot"
juno32_recovery_root_oe="$linaro_release/juno32-latest-oe-uboot"

juno_rootfs_url="$linaro_release/linaro-image-minimal-genericarmv8-20170127-888.rootfs.tar.gz"
juno32_rootfs_url="$linaro_release/linaro-image-alip-genericarmv7a-20150710-336.rootfs.tar.gz"

# FIXME use optee pre-built binaries
get_optee_bin() {
	local tmpdir="$(mktempdir)"

	pushd "$tmpdir"
	extract_fip "$optee_fip_url"
	mv "tos-fw.bin" "bl32.bin"
	archive_file "bl32.bin"
	popd
}

get_scp_bl2_bin() {
	url="$scp_bl2_url" saveas="scp_bl2.bin" fetch_file
	archive_file "scp_bl2.bin"
}

get_psci_reset2_scp_bl2_bin() {
	url="$psci_reset2_scp_bl2_url" saveas="scp_bl2.bin" fetch_file
	archive_file "scp_bl2.bin"
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
	url="$uboot_bl33_url" saveas="uboot.bin" fetch_file
	archive_file "uboot.bin"
}

gen_recovery_image32() {
	url="$juno32_recovery_root" gen_recovery_image "$@"
}

gen_recovery_image32_oe() {
	url="$juno32_recovery_root_oe" gen_recovery_image "$@"
}

gen_recovery_image() {
	local zip_dir="$workspace/juno_recovery"
	local zip_file="${zip_dir}.zip"
	local url="${url:-$juno_recovery_root}"

	saveas="$zip_dir" url="$url" fetch_directory
	if [ "$*" ]; then
		cp -f "$@" "$zip_dir/SOFTWARE"
	fi

	# If an image.txt file was specified, replace all image.txt file inside
	# the recovery with the specified one.
	if upon "$image_txt"; then
		find "$zip_dir" -name images.txt -exec cp -f "$image_txt" {} \;
	fi

	(cd "$zip_dir" && zip -rq "$zip_file" -- *)
	archive_file "$zip_file"
}

gen_juno_yaml() {
	local yaml_file="$workspace/juno.yaml"
	local payload_type="${payload_type:?}"

	bin_mode="$mode" \
		"$ci_root/script/gen_juno_${payload_type}_yaml.sh" > "$yaml_file"

	archive_file "$yaml_file"
}

juno_aarch32_runtime() {
	# Build BL32 for Juno in AArch32. Since build_tf does a realclean, we'll
	# lose the fiptool binary. Build that again for later use.
	echo "Building BL32 in AArch32 for Juno:"
	sed 's/^/\t/' < "${config_file:?}"
	tf_build_config="$config_file" tf_build_targets="fiptool bl32" \
		build_tf

	# Copy BL32 to a temporary directoy, and update it in the FIP
	local tmpdir="$(mktempdir)"
	from="$tf_root/build/juno/$mode" to="$tmpdir" collect_build_artefacts
	bin_name="tos-fw" src="$tmpdir/bl32.bin" fip_update
}

set +u
