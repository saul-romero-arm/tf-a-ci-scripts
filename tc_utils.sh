#!/usr/bin/env bash
#
# Copyright (c) 2020-2022, Arm Limited. All rights reserved.
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

rss_rom_addr=0x11000000
rss_flash_addr=0x31000000
vmmaddrwidth=23
rvbaddr_lw=0x1000
rvbaddr_up=0x0000

# AP bl1 0x00 is mapped to 0x70010000 in RSS memory map
ap_bl1_flash_load_addr=0x70010000
ap_bl1_flash_size=0x20000

# Hafnium build repo containing Secure hafnium binaries
spm_secure_out_dir=secure_tc_clang

# TC platform doesnt have non secure hafnium build configuration. Hence, we
# set it to an arbitrary name.
spm_non_secure_out_dir=not_found
