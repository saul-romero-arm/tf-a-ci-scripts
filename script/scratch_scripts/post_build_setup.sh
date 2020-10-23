#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# THIS SCRIPT IS SOURCED!
#
# This script exists only to obtain a meaningful value for $CI_ROOT, the root
# directory for CI scripts, from which other post-build scripts are executed.
# Normally, $CI_ROOT *would* be available via. environment injection, but if a job
# failed in its early stages, it wouldn't.

# Although env file is meant to be sourced, RHS might have white spaces in it,
# so sourcing will fail.
set_ci_root() {
	if [ -d "platform-ci/trusted-fw/new-ci" ]
	then
		ci_root="platform-ci/trusted-fw/new-ci"
	else
		ci_root="platform-ci"
	fi
}
if [ -f "$WORKSPACE/env" ]; then
	source "$WORKSPACE/env" 2>/dev/null || true
fi

if [ -z "$CI_ROOT" ] && [ -d "$WORKSPACE/platform-ci" ]; then
	set_ci_root
	CI_ROOT=$ci_root
fi

if [ -z "$CI_ROOT" ]; then
	echo "warning: couldn't not determine value for \$CI_ROOT"
fi
