#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/FVP_Base_Zeusx4"

# Option not supported on Zeus FVP yet.
export no_quantum=""

source "$ci_root/model/fvp_common.sh"
