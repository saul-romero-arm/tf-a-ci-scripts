#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Build
"$CI_ROOT/script/build_package.sh"

if [ "$skip_runs" ]; then
	exit 0
fi

# Execute test locally for FVP configs
if [ "$RUN_CONFIG" != "nil" ] && echo "$RUN_CONFIG" | grep -iq '^fvp'; then
	"$CI_ROOT/script/run_package.sh"
fi
