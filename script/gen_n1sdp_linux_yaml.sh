#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a YAML file in order to dispatch N1SDP runs on LAVA. Note that this
# script would produce a meaningful output when run via. Jenkins
#
# $bin_mode must be set. This script outputs to STDOUT

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"
source "$ci_root/n1sdp_utils.sh"

get_recovery_image_url() {
        local build_job="tf-build"
        local bin_mode="${bin_mode:?}"

        if upon "$jenkins_run"; then
                echo "$jenkins_url/job/$JOB_NAME/$BUILD_NUMBER/artifact/artefacts/$bin_mode/n1sdp-board-firmware_primary.zip"
        else
                echo "file://$workspace/artefacts/$bin_mode/n1sdp-board-firmware_primary.zip"
        fi
}

recovery_img_url="${recovery_img_url:-$(get_recovery_image_url)}"

expand_template "$(dirname "$0")/lava-templates/n1sdp-linux.yaml"
