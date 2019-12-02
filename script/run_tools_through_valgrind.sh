#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"

# Change directory to the TF-A checkout ready to build
cd "$TF_CHECKOUT_LOC"

# Build TF-A to get blx.bin images and the tools (fiptool and cert_create)
# Debug build enabled so that valgrind has access to source file line numbers
if ! make CROSS_COMPILE="aarch64-linux-gnu-" all fiptool certtool DEBUG=1 V=1 \
		&>"$workspace/build.log"; then
	echo "Error building tools; see archived build.log"
	exit 1
fi

run_valgrind() {
	valgrind --leak-check=full -v --log-file="$log_file" $*
	echo
	if ! grep -iq "All heap blocks were freed -- no leaks are possible" \
			"$log_file"; then
		echo "Memory leak reported in $log_file"
		return 1
	fi
	return 0
}

has_leak=0

fiptool_cmd="./tools/fiptool/fiptool \
	create \
	--tb-fw build/fvp/debug/bl2.bin \
	--soc-fw build/fvp/debug/bl31.bin \
	fip.bin"

# Build the FIP under Valgrind
if ! log_file="$workspace/fiptool.log" run_valgrind "$fiptool_cmd"; then
	echo "fiptool has memory leaks."
	has_leak=1
else
	echo "fiptool does not have memory leaks."
fi

echo

cert_create_cmd="./tools/cert_create/cert_create \
	-n \
	--tb-fw build/fvp/debug/bl2.bin"

# Run cert_create under Valgrind
if ! log_file="$workspace/cert_create.log" run_valgrind "$cert_create_cmd"; then
	echo "cert_create has memory leaks."
	has_leak=1
else
	echo "cert_create does not have memory leaks."
fi

echo

exit "$has_leak"
