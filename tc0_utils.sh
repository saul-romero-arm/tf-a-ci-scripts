#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

tc_prebuilts="${tc_prebuilts:-$tfa_downloads/total_compute/tc0}"

fvp_kernels[fvp-tc-kernel]="$tc_prebuilts/Image"
fvp_initrd_urls[fvp-tc-ramdisk]="$tc_prebuilts/uInitrd-busybox.0x88000000"

initrd_addr=0x8000000
kernel_addr=0x80000
scp_ram_addr=0x0bd80000
