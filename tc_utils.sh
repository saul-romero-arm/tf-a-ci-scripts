#!/usr/bin/env bash
#
# Copyright (c) 2020-2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

tc_prebuilts="${tc_prebuilts:-$tfa_downloads/total_compute}"

# Pre-built SCP binaries
scp_prebuilts="${scp_prebuilts:-$scp_mcp_downloads}"

fvp_kernels[fvp-tc-kernel]="$tc_prebuilts/Image"
fvp_initrd_urls[fvp-tc-ramdisk]="$tc_prebuilts/uInitrd-busybox.0x88000000"

initrd_addr=0x8000000
kernel_addr=0x80000
scp_ram_addr=0x0bd80000

# Hafnium build repo containing Secure hafnium binaries
spm_secure_out_dir=secure_tc_clang

# TC platform doesnt have non secure hafnium build configuration. Hence, we
# set it to an arbitrary name.
spm_non_secure_out_dir=not_found
