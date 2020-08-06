#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

post_tf_build() {
	url="$project_filer/ci-files/spm-07-29-2020/secure_hafnium.bin" fetch_file
	url="$project_filer/ci-files/spm-07-29-2020/spmc_sel2_optee_sel1.bin" fetch_file

	archive_file "secure_hafnium.bin"
	archive_file "spmc_sel2_optee_sel1.bin"

	cp "${archive}/spmc_sel2_optee_sel1.bin" "${tf_root}/build/fvp/${bin_mode}"

cat <<EOF > "${tf_root}/build/fvp/${bin_mode}/optee_sp_layout.json"
{
	"op-tee" : {
		"image": "spmc_sel2_optee_sel1.bin",
		"pm": "${tf_root}/fdts/optee_sp_manifest.dts"
	}
}
EOF

	build_fip BL33="$archive/tftf.bin" BL32="$archive/secure_hafnium.bin"
}

post_fetch_tf_resource() {
	model="base-aemv8a" \
	arch_version="8.4" \
		gen_model_params
}

fetch_tf_resource() {
	# Expect scripts
	uart="0" file="tftf.exp" track_expect
	uart="1" file="spm-optee-sp-uart1.exp" track_expect
}
