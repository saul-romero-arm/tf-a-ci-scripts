#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a FVP-TFTF model agnostic YAML template. Note that this template is not ready to be
# sent to LAVA by Jenkins so in order to produce file, variables in ${UPPERCASE} must be replaced
# to correct values

cat <<EOF
device_type: fvp
job_name: fvp-tftf

timeouts:
  connection:
    minutes: 3
  job:
    minutes: 60
  actions:
    auto-login-action:
      minutes: 5
    http-download:
      minutes: 2
    download-retry:
      minutes: 2
    fvp-deploy:
      minutes: 5

priority: medium
visibility: public

actions:
- deploy:
    to: fvp
    images:
      bl1:
        url: \${ACTIONS_DEPLOY_IMAGES_BL1}
      fip:
        url: \${ACTIONS_DEPLOY_IMAGES_FIP}
      ns_bl1u:
        url: \${ACTIONS_DEPLOY_IMAGES_NS_BL1U}
      ns_bl2u:
        url: \${ACTIONS_DEPLOY_IMAGES_NS_BL2U}
      el3_payload:
        url: \${ACTIONS_DEPLOY_IMAGES_EL3_PAYLOAD}

- boot:
    method: fvp
    license_variable: ARMLMD_LICENSE_FILE=\${ARMLMD_LICENSE_FILE}
    docker:
      name: \${BOOT_DOCKER_NAME}
      local: true
    image: \${BOOT_IMAGE_DIR}/\${BOOT_IMAGE_BIN}
    version_string: \${BOOT_VERSION_STRING}
    console_string: 'terminal_0: Listening for serial connection on port (?P<PORT>\d+)'
    timeout:
      minutes: 30

    arguments:
\${BOOT_ARGUMENTS}

- test:
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
