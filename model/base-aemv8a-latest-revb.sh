#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/0.8/9810/models/Linux64_GCC-4.9/FVP_Base_AEMv8A-AEMv8A"

default_var sve_plugin_path "$warehouse/SysGen/ShojiPlugin/0.8/9905/hpc-00rel3/Linux64_GCC-4.9/ScalableVectorExtension.so"

source "$ci_root/model/base-aemv8a-common.sh"
