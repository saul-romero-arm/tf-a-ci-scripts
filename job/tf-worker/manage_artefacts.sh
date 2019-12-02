#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

if [ -d artefacts ]; then
	# Remove everything except logs
	find artefacts -type f -not \( -name "*.log" \) -exec rm -f {} +
fi
