#!/usr/bin/env bash
#
# Copyright (c) 2020-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version_11_16/$model_build_11_16/external/models/$model_flavour_11_16/FVP_Base_Neoverse-N1x4"

source "$ci_root/model/fvp_common.sh"
