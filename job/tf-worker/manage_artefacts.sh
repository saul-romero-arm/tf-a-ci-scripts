#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

if [ -d artefacts ]; then
	# Remove everything except logs and scan-build artefacts such as
	# .html, .js and .css files useful for offline debug of static
	# analysis defects
	find artefacts -type f -not \( -name "*.log" -o -name "*.html" -o -name "*.js" -o -name "*.css" \) -exec rm -f {} +
fi
