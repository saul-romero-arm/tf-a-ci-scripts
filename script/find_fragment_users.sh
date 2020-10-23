#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

ci_root="$(readlink -f "$(dirname "$0")/..")"
run_config_dir="$ci_root/run_config"

run_config="$1"
if [ -z "$run_config" ]; then
	echo "Run config exected as parameter"
	exit 1
elif [ ! -f "$run_config_dir/$run_config" ]; then
	echo "Run config $run_config not found"
	exit 1
fi

for test_config in $(cd "$ci_root/group" && find -type f -printf "%P\n"); do
	if echo "$run_config_part" | grep -q ":nil$"; then
		continue;
	fi

	if "$ci_root/script/gen_run_config_candidates.py" "$test_config" | \
			grep -q "^$run_config$"; then
		echo "$test_config"
	fi
done
