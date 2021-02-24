#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

morello_prebuilts=${morello_prebuilts:="$tfa_downloads/morello"}

uefi_addr=0x14200000
