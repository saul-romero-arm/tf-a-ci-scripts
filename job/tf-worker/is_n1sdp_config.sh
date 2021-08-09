#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# For n1sdp runs, we need to let the board download build artefacts using a URL.
# The only way to have a board-accessible URL at the moment is to have build
# artefacts archived. Therefore, for n1sdp we spawn the build as a separate job
if echo "$RUN_CONFIG" | grep -iqe '^n1sdp'; then
        exit 0
else
        exit 1
fi
