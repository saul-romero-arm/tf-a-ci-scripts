#!/usr/bin/env bash
#
# Copyright (c) 2019-2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a FVP-TFTF model agnostic YAML template. Note that this template is not ready to be
# sent to LAVA by Jenkins so in order to produce file, variables in ${UPPERCASE} must be replaced
# to correct values

cat <<EOF
metadata:
  test_config: {TEST_CONFIG}

device_type: fvp
job_name: fvp-tftf-{MODEL}

timeouts:
  job:
    minutes: 60
  action:
    minutes: 50
  actions:
    auto-login-action:
      seconds: 300
    lava-test-monitor:
      minutes: 45
    lava-test-shell:
      seconds: 300
    lava-test-retry:
      seconds: 300
    http-download:
      seconds: 120
    download-retry:
      seconds: 120
    fvp-deploy:
      seconds: 300
  connection:
    minutes: 3
  connections:
    lava-test-retry:
      seconds: 300
    lava-test-monitor:
      seconds: 300
    lava-test-shell:
      seconds: 300
    bootloader-action:
      seconds: 300
    bootloader-retry:
      seconds: 300

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
      busybox:
        url: {BUSYBOX}
        compression: gz
      cactus_primary:
        url: {CACTUS_PRIMARY}
      cactus_secondary:
        url: {CACTUS_SECONDARY}
      cactus_tertiary:
        url: {CACTUS_TERTIARY}
      coverage_trace_plugin:
        url: {COVERAGE_TRACE_PLUGIN}
      dtb:
        url: {DTB}
      el3_payload:
        url: {EL3_PAYLOAD}
      fip:
        url: {FIP}
      fip_gpt:
        url: {FIP_GPT}
      fwu_fip:
        url: {FWU_FIP}
      generic_trace:
        url: {GENERIC_TRACE}
      hafnium:
        url: {HAFNIUM}
      image:
        url: {IMAGE}
      mcp_rom:
        url: {MCP_ROM}
      mcp_rom_hyphen:
        url: {MCP_ROM_HYPHEN}
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
      secure_hafnium:
        url: {SECURE_HAFNIUM}
      scp_ram:
        url: {SCP_RAM}
      scp_ram_hyphen:
        url: {SCP_RAM_HYPHEN}
      scp_rom:
        url: {SCP_ROM}
      scp_rom_hyphen:
        url: {SCP_ROM_HYPHEN}
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
    arguments:
{BOOT_ARGUMENTS}

EOF
