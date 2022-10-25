#!/usr/bin/env bash
#
# Copyright (c) 2020-2022, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -u

gen_mt8192_yaml(){
    local yaml_file="$workspace/mt8192.yaml"
    local job_file="$workspace/job.yaml"
    local payload_type="${payload_type:?}"

    bin_mode="$mode" \
        "$ci_root/script/gen_mt8192_${payload_type}_yaml.sh" > "$yaml_file"

    cp "$yaml_file" "$job_file"
    archive_file "$yaml_file"
    archive_file "$job_file"
}

set +u
