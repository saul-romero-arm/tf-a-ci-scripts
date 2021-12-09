#!/usr/bin/env bash
#
# Copyright (c) 2021-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

source "$ci_root/fvp_utils.sh"

morello_prebuilts=${morello_prebuilts:="$tfa_downloads/morello"}

# TODO: Restore this path once the SCP release v2.10 binaries are generated
#scp_mcp_prebuilts=${scp_mcp_prebuilts:="$scp_mcp_downloads/morello/release"}
scp_mcp_prebuilts=${scp_mcp_prebuilts:="$tfa_downloads/morello/"}
