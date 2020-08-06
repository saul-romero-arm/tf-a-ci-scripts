#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a YAML file in order to dispatch Juno TFTF runs on LAVA. Note that
# this script would produce a meaningful output when run via. Jenkins.
#
# $bin_mode must be set. This script outputs to STDOUT

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"

get_recovery_image_url() {
	local build_job="tf-build"
	local bin_mode="${bin_mode:?}"

	if upon "$jenkins_run"; then
		echo "$jenkins_url/job/$JOB_NAME/$BUILD_NUMBER/artifact/artefacts/$bin_mode/juno_recovery.zip"
	else
		echo "file://$workspace/artefacts/$bin_mode/juno_recovery.zip"
	fi
}

juno_revision="${juno_revision:-juno-r0}"
recovery_img_url="${recovery_img_url:-$(get_recovery_image_url)}"

cat <<EOF
device_type: juno
job_name: tf-juno

tags:
- $juno_revision

timeouts:
  # Global timeout value for the whole job.
  job:
    minutes: 45
  actions:
    lava-test-monitor:
      seconds: 120
  connections:
    lava-test-monitor:
      seconds: 120

priority: medium
visibility: public

actions:

- deploy:
    timeout:
      minutes: 10
    to: vemsd
    recovery_image:
      url: $recovery_img_url
      compression: zip

- boot:
    method: minimal

- test:
    # Timeout for all the TFTF tests to complete.
    timeout:
      minutes: 30

    monitors:
    - name: TFTF
      # LAVA looks for a testsuite start string...
      start: 'Booting trusted firmware test framework'
      # ...and a testsuite end string.
      end: 'Exiting tests.'

      # For each test case, LAVA looks for a string which includes the testcase
      # name and result.
      pattern: "(?s)> Executing '(?P<test_case_id>.+?(?='))'(.*)  TEST COMPLETE\\\s+(?P<result>(Skipped|Passed|Failed|Crashed))"

      # Teach to LAVA how to interpret the TFTF Tests results.
      fixupdict:
        Passed: pass
        Failed: fail
        Crashed: fail
        Skipped: skip
EOF
