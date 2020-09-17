#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/FVP_Base_Neoverse-V1x4"

# Option not supported on Neoverse FVP yet.
export no_quantum=""

source "$ci_root/model/fvp_common.sh"
