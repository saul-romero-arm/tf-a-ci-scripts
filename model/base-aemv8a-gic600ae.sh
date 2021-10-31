#!/usr/bin/env bash
#
# Copyright (c) 2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/external/models/$model_flavour/FVP_Base_AEMv8A-GIC600AE"

default_var sve_plugin_path "$warehouse/SysGen/PVModelLib/0.0/6415/external/plugins/$model_flavour/sve2-HEAD/ScalableVectorExtension.so"

source "$ci_root/model/base-aemva-common.sh"

cat <<EOF >>"$model_param_file"
-C gic_iri.reg-base-per-redistributor=0.0.0.0=0x2f100000,0.0.0.1=0x2f120000,0.0.0.2=0x2f140000,0.0.0.3=0x2f160000,0.0.1.0=0x2f180000,0.0.1.1=0x2f1a0000,0.0.1.2=0x2f1c0000,0.0.1.3=0x2f1e0000
EOF
