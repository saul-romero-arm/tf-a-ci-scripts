#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/Foundation_Platform"

default_var ncores 4
default_var quantum 1000

cat <<EOF >"$model_param_file"

--no-visualization
--data=$bl1_bin@$bl1_addr
${fip_bin+--data=$fip_bin@$fip_addr}
${dtb_bin+--data=$dtb_bin@$dtb_addr}
${kernel_bin+--data=$kernel_bin@$kernel_addr}
${initrd_bin+--data=$initrd_bin@$initrd_addr}
${rootfs_bin+--block-device=$rootfs_bin}
--cores=$ncores
--secure-memory
--gicv3
--quantum=$quantum
${arch_version+--arm-v$arch_version}
${bmcov_plugin+--plugin=$bmcov_plugin_path}
EOF
