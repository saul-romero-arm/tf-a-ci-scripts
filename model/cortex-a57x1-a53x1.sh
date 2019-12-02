#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/Linux64_GCC-4.9/FVP_Base_Cortex-A57x1-A53x1"

source "$ci_root/model/fvp_common.sh"

cat <<EOF >>"$model_param_file"

${reset_to_bl31+-C cluster0.cpu0.RVBARADDR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu0.RVBARADDR=${bl31_addr:?}}

EOF
