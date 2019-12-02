#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

if [ "$SKIP_STATIC" = "true" ]; then
	exit 1
else
	exit 0
fi
