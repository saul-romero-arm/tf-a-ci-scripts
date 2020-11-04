#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

sgi_prebuilts="${sgi_prebuilts:-$css_downloads/sgi/rddaniel}"

# Pre-built SCP/MCP v2.7.0 release binaries
scp_mcp_prebuilts="${scp_mcp_prebuilts:-$css_downloads_270/sgi/rddaniel}"

fvp_kernels[fvp-sgi-busybox]="$sgi_prebuilts/Image"
fvp_initrd_urls[fvp-sgi-ramdisk]="$sgi_prebuilts/ramdisk-busybox.img"

scp_ram_addr=0x0bd80000
mcp_ram_addr=0x0be00000
