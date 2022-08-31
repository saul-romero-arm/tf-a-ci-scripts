#!/usr/bin/env bash
#
# Copyright (c) 2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a YAML file in order to dispatch Juno runs on LAVA. Note that this
# script would produce a meaningful output when run via Jenkins
#
# This is used exclusively to run a SCMI conformance test for SCP-Firmware on
# Juno.

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"
source "$ci_root/juno_utils.sh"

get_recovery_image_url() {
	local build_job="tf-build"
	local bin_mode="debug"

	if upon "$jenkins_run"; then
		echo "$jenkins_url/job/$JOB_NAME/$BUILD_NUMBER/artifact/artefacts/$bin_mode/juno_recovery.zip"
	else
		echo "file://$workspace/artefacts/$bin_mode/juno_recovery.zip"
	fi
}

recovery_img_url="${recovery_img_url:-$(get_recovery_image_url)}"

# Allow running juno tests on specific revision(r0/r1/r2).
juno_revision="${juno_revision:-}"
if [ ! -z "$juno_revision" ]; then
        tags="tags:"
        juno_revision="- ${juno_revision}"
else
        tags=""
fi

expand_template "$(dirname "$0")/lava-templates/juno-scp-tests-scmi.yaml"
