#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Use revc model
if  is_arm_jenkins_env || upon "$local_ci"; then
        set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/external/models/$model_flavour/FVP_Base_RevC-2xAEMvA"
        default_var sve_plugin_path "$warehouse/SysGen/PVModelLib/$model_version/$model_build/external/plugins/$model_flavour/sve2-HEAD/ScalableVectorExtension.so"
else
        # OpenCI enviroment
        source "$ci_root/fvp_utils.sh"

        # fvp_models variable contains the information for FVP paths, where 2nd field
	# points to the /opt/model/*/models/${model_flavour}
	models_dir="$(echo ${fvp_models[$model]} | awk -F ';' '{print $2}')"
        set_model_path "$models_dir"

        # ScalableVectorExtension is located at /opt/model/*/plugins/${model_flavour}
        default_var sve_plugin_path "${models_dir/models/plugins}/ScalableVectorExtension.so"
fi

default_var is_dual_cluster 1

source "$ci_root/model/base-aemva-common.sh"

# Base address for each redistributor
if [ "$gicd_virtual_lpi" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C gic_distributor.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.1.0=0x2f140000,0.0.2.0=0x2f180000,0.0.3.0=0x2f1c0000,0.1.0.0=0x2f200000,0.1.1.0=0x2f240000,0.1.2.0=0x2f280000,0.1.3.0=0x2f2c0000
-C gic_distributor.print-memory-map=1
EOF
fi
