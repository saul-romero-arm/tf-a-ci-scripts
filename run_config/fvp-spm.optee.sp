#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

post_tf_build() {
	url="$tfa_downloads/spm/02-05-2021/spmc_sel2_optee_sel1.bin" fetch_file

	archive_file "spmc_sel2_optee_sel1.bin"
	cp "${archive}/spmc_sel2_optee_sel1.bin" "${tf_root}/build/fvp/${bin_mode}"

cat <<EOF > "${tf_root}/build/fvp/${bin_mode}/optee_sp_layout.json"
{
	"op-tee" : {
		"image": "spmc_sel2_optee_sel1.bin",
		"pm": "${tf_root}/plat/arm/board/fvp/fdts/optee_sp_manifest.dts"
	}
}
EOF

	build_fip BL33="$archive/tftf.bin" BL32="$archive/secure_hafnium.bin"
}

fetch_tf_resource() {
	# Expect scripts
	uart="0" file="tftf.exp" track_expect
	uart="1" file="spm-optee-sp-uart1.exp" track_expect
}

post_fetch_tf_resource() {
        local model="base-aemv8a"

	model="$model" arch_version="8.4" gen_model_params
	model="$model" gen_fvp_yaml
}
