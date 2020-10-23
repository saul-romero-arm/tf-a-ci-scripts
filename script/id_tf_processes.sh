#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

lookup() {
	local string

	string="$(grep "\\<${1:?}=" < "$proc_file")"
	if [ "$string" ]; then
		echo "$string"
		eval "$string"
	fi
}

for p in $(pgrep FVP); do
	proc_file="$WORKSPACE/proc_file"
	tr '\000' '\n' < "/proc/$p/environ" > "$proc_file"

	echo "PID: $p"
	lookup "TRUSTED_FIRMWARE_CI"
	lookup "BUILD_NUMBER"
	lookup "JOB_NAME"

	if [ "$KILL_PROCESS" = "true" -a "$TRUSTED_FIRMWARE_CI" = "1" ]; then
		kill -SIGTERM "$p"
		echo "Killed $p"
	fi

	echo
done
