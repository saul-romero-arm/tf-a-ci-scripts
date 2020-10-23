#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a FVP-Linux model agnostic YAML template. Note that this template is not ready to be
# sent to LAVA by Jenkins so in order to produce file, variables in ${UPPERCASE} must be replaced
# to correct values

cat <<EOF
device_type: fvp
job_name: tf-fvp

timeouts:
  connection:
    minutes: 3
  job:
    minutes: 10
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
      dtb:
        url: \${ACTIONS_DEPLOY_IMAGES_DTB}
      image:
        url: \${ACTIONS_DEPLOY_IMAGES_IMAGE}
      ramdisk:
        url: \${ACTIONS_DEPLOY_IMAGES_RAMDISK}

- boot:
    method: fvp
    docker:
      name: \${BOOT_DOCKER_NAME}
      local: true
    image: \${BOOT_IMAGE}
    version_string: \${BOOT_VERSION_STRING}
    timeout:
      minutes: 7
    console_string: 'terminal_0: Listening for serial connection on port (?P<PORT>\d+)'
    arguments:
\${BOOT_ARGUMENTS}
    prompts:
    - '/ #'
EOF
