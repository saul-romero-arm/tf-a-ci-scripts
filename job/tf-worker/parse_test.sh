#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Parse test config. This produces $workspace/env file
$CI_ROOT/script/parse_test.sh
