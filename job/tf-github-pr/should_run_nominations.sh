#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

nom_file="$WORKSPACE/nominations"
rules_file="$CI_ROOT/script/trusted-firmware.nomination.py"
if [ -f "$rules_file" ]; then
	cd "$TF_CHECKOUT_LOC"
	"$CI_ROOT/script/gen_nomination.py" "$rules_file" > "$nom_file"
	if [ -s "$nom_file" ]; then
		exit 0
	else
		# No nominations
		exit 1
	fi
fi

exit 1
