#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

if echo "$RUN_CONFIG" | grep -iq 'tftf'; then
	payload_type="tftf"
elif echo "$RUN_CONFIG" | grep -iq 'scmi'; then
	payload_type="scp_tests_scmi"
else
	payload_type="linux"
fi

"$CI_ROOT/script/parse_lava_job.py" --payload-type "$payload_type"
