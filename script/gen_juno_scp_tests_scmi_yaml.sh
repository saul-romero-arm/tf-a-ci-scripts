#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
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

juno_revision="${juno_revision:-juno-r0}"
recovery_img_url="${recovery_img_url:-$(get_recovery_image_url)}"

cat <<EOF
device_type: juno
job_name: scp-tests-scmi-juno

tags:
- $juno_revision

timeouts:
  # Global timeout value for the whole job.
  job:
    minutes: 10
  actions:
    lava-test-monitor:
      seconds: 180
  connections:
    lava-test-monitor:
      seconds: 180

priority: medium
visibility: public

actions:

- deploy:
    timeout:
      minutes: 5
    to: vemsd
    recovery_image:
      url: $recovery_img_url
      compression: zip

- boot:
    method: minimal

- test:
    timeout:
      minutes: 8

    monitors:
    #
    # Monitor no.1
    # Monitor the results from all the protocols but sensor
    #
    - name: SCP-SCMI-NON-SENSOR-PROTOCOL
      start: 'BL31: Baremetal test suite: scmi'
      end: 'Protocol Sensor'

      pattern: "\\\[(base|power|system_power|performance)\\\](-|_){(?P<test_case_id>\\\D*)(.*)}(-|_)(query|power|system_power|performance|precondition)_(.*)-01: (?P<result>(CONFORMANT|NON CONFORMANT))"

      fixupdict:
        "CONFORMANT": pass
        "NON CONFORMANT": fail

    #
    # Monitor no.2
    # Monitor the results from the sensor protocols but for reading_get
    #
    - name: SCP-SCMI-SENSOR-PROTOCOL
      start: 'SENSOR_DISCOVERY:'
      end: 'query_sensor_description_get_non_existant_sensorid'

      pattern: "\\\[(sensor)\\\](-|_){(?P<test_case_id>\\\D*)(.*)}(-|_)(query|sensor)_(.*)-01: (?P<result>(CONFORMANT|NON CONFORMANT))"

      fixupdict:
        "CONFORMANT": pass
        "NON CONFORMANT": fail

    #
    # Monitor no.3
    # Monitor the results from each individual sensor when performing the reading_get
    # This special case is required since the baremetal application does not have
    #     any knowledge of the power state of the system. This results in a blind
    #     call to all the available sensors exposed by the platform, including ones
    #     tied to specific power domains that are in off state. The driver is then
    #     refusing to provide a reading for those sensors, causing a known fail for
    #     the test.
    #     The parser will therefore discard false failures.
    #
    - name: SCP-SCMI-SENSOR-PROTOCOL-GET
      start: 'SENSOR_READING_GET:'
      end: 'SCMI TEST: END'

      pattern: "SENSOR ID (?P<test_case_id>\\\d+)[\\\n|\\\r](.*)MESSAGE_ID = 0x06[\\\n|\\\r](.*)PARAMETERS (.*)[\\\n|\\\r](.*)CHECK HEADER:(.*)[\\\n|\\\r](.*)CHECK STATUS: (?P<result>(PASSED|FAILED))"

      fixupdict:
        "PASSED": pass
        "FAILED": fail



    #
    # We have already tested with one agent above and the expectations are the
    # same for the two agents.
    # Collect the final results.
    #
    - name: SCP-SCMI
      start: 'Test Suite: SCMI 140'
      end: 'End of Test Suite: SCMI'

      pattern: "\\\[UT\\\] Test Case: (?P<test_case_id>\\\D*)(.*) Result: (?P<result>[0-9])"

      fixupdict:
        "0": pass
        "1": fail
        "2": fail
        "3": fail
        "4": fail
        "5": fail
        "6": fail
        "7": fail
        "8": fail
        "9": fail



EOF
