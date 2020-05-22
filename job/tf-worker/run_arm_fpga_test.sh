#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Build
"$CI_ROOT/script/build_package.sh"

if [ "$skip_runs" ]; then
	exit 0
fi

# Execute test locally for arm_fpga configs
if [ "$RUN_CONFIG" != "nil" ] && echo "$RUN_CONFIG" | grep -iq '^arm_fpga'; then
	"$CI_ROOT/script/test_fpga_payload.sh"
fi
