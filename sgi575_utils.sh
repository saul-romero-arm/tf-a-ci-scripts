#!/usr/bin/env bash
#
# Copyright (c) 2019-2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

# Pre-built SCP/MCP v2.8.0-dev release binaries
# Files from
# https://releases.linaro.org/members/arm/platforms/20.01/sgi575-latest-busybox-uefi.zip
# Tianocore/EDK2 firmware version 2321f49f07 copied from
# http://files.oss.arm.com/downloads/tf-a/css/sgi/sgi575
sgi_prebuilts="${sgi_prebuilts:-$css_downloads_280/sgi/sgi575}"

fvp_kernels[fvp-sgi-busybox]="$sgi_prebuilts/Image"
fvp_initrd_urls[fvp-sgi-ramdisk]="$sgi_prebuilts/ramdisk-busybox.img"

scp_ram_addr=0x0bd80000
mcp_ram_addr=0x0be00000
