#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/FVP_Base_Cortex-A55x4+Cortex-A75x4"

source "$ci_root/model/fvp_common.sh"
