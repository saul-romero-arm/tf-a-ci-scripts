#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

sgm_prebuilts="${sgm_prebuilts:-$css_downloads/sgm/sgm775}"

fvp_kernels[fvp-sgm-kernel]="$sgm_prebuilts/uImage.0x80080000.mobile_bb"
fvp_initrd_urls[fvp-sgm-ramdisk]="$sgm_prebuilts/uInitrd-busybox.0x88000000"

initrd_addr=0x88000000
scp_ram_addr=0x0bd80000
