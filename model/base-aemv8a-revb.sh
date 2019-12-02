#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Use revb model
set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/Linux64_GCC-4.9/FVP_Base_AEMv8A-AEMv8A"

default_var sve_plugin_path "$warehouse/SysGen/ShojiPlugin/$model_version/$model_build/hpc-00rel4_1/Linux64_GCC-4.9/ScalableVectorExtension.so"

source "$ci_root/model/base-aemv8a-common.sh"
