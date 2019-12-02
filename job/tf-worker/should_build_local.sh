#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# If it's a Juno build-only config, or an FVP config, we do everything locally
if [ "$RUN_CONFIG" = "nil" ]; then
	exit 0
fi

case "$RUN_CONFIG" in
	fvp-*)
		exit 0;;
	coverity-*)
		exit 0;;
esac

# If we're not going to run Juno, then no need to spawn tf-build-for lava;
# build it locally.
if [ "$skip_juno" ]; then
	exit 0
fi

exit 1
