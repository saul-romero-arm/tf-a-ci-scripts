#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This script runs the static checks in tf-static-checks
# jenkins job.

if [ "$REPO_UNDER_TEST" = "trusted-firmware" ]; then
	cd "$TF_CHECKOUT_LOC"
else
	cd "$TFTF_CHECKOUT_LOC"
fi

export IS_CONTINUOUS_INTEGRATION=1
static_fail=0

if ! "$CI_ROOT/script/static-checks/static-checks.sh"; then
	static_fail=1
fi

if [ -f "static-checks.log" ]; then
	mv "static-checks.log" "$WORKSPACE"
fi

exit "$static_fail"
