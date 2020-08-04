#!/bin/bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Use revc model
set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/FVP_Base_RevC-2xAEMv8A"

default_var sve_plugin_path "$warehouse/SysGen/ShojiPlugin/$model_version/$model_build/v9.0-00bet4/$model_flavour/ScalableVectorExtension.so"

default_var is_dual_cluster 1

source "$ci_root/model/base-aemva-common.sh"

# Base address for each redistributor
if [ "$gicd_virtual_lpi" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C gic_distributor.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.1.0=0x2f140000,0.0.2.0=0x2f180000,0.0.3.0=0x2f1c0000,0.1.0.0=0x2f200000,0.1.1.0=0x2f240000,0.1.2.0=0x2f280000,0.1.3.0=0x2f2c0000
-C gic_distributor.print-memory-map=1
EOF
fi
