#!/usr/bin/env bash

#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

python3 -m venv .venv && \
    . .venv/bin/activate && \
    python3 -m pip install -r "$tf_root/docs/requirements.txt"
