#!/usr/bin/env bash

#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

python3 -m venv .venv && \
    source .venv/bin/activate && \
    python3 -m pip install -r "${tf_root}/docs/requirements.txt" \
        --cache-dir "${project_filer}/pip-cache" --retries 30 --verbose
