#!/usr/bin/env bash
#
# Copyright (c) 2019-2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a FVP-Linux model agnostic YAML template. Note that this template is not ready to be
# sent to LAVA by Jenkins so in order to produce file, variables in ${UPPERCASE} must be replaced
# to correct values

cat <<EOF
device_type: fvp
job_name: fvp-linux-{MODEL}

timeouts:
  connection:
    minutes: 3
  job:
    minutes: 30
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
      backup_fip:
        url: {BACKUP_FIP}
      bl1:
        url: {BL1}
      bl2:
        url: {BL2}
      bl31:
        url: {BL31}
      bl32:
        url: {BL32}
      dtb:
        url: {DTB}
      el3_payload:
        url: {EL3_PAYLOAD}
      fip:
        url: {FIP}
      fwu_fip:
        url: {FWU_FIP}
      image:
        url: {IMAGE}
      ns_bl1u:
        url: {NS_BL1U}
      ns_bl2u:
        url: {NS_BL2U}
      ramdisk:
        url: {RAMDISK}
      romlib:
        url: {ROMLIB}
      rootfs:
        url: {ROOTFS}
        compression: gz
      spm:
        url: {SPM}
      tftf:
        url: {TFTF}
      tmp:
        url: {TMP}
      uboot:
        url: {UBOOT}

- boot:
    method: fvp
    license_variable: ARMLMD_LICENSE_FILE={ARMLMD_LICENSE_FILE}
    docker:
      name: {BOOT_DOCKER_NAME}
      local: true
    image: {BOOT_IMAGE_DIR}/{BOOT_IMAGE_BIN}
    version_string: {BOOT_VERSION_STRING}
    console_string: 'terminal_0: Listening for serial connection on port (?P<PORT>\d+)'
    feedbacks:
      - '(?P<NAME>terminal_1): Listening for serial connection on port (?P<PORT>\d+)'
      - '(?P<NAME>terminal_2): Listening for serial connection on port (?P<PORT>\d+)'
      - '(?P<NAME>terminal_3): Listening for serial connection on port (?P<PORT>\d+)'
    timeout:
      minutes: 30
    arguments:
{BOOT_ARGUMENTS}
    prompts:
    - '{PROMPT1}'
    - '{PROMPT2}'
EOF
