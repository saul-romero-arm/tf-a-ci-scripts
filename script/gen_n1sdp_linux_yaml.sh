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

cat <<EOF
device_type: n1sdp
job_name: tf-n1sdp
timeouts:
  job:
    minutes: 30

priority: medium
visibility: public
context:
  extra_nfsroot_args: ',vers=3'
  extra_kernel_args: rootwait
actions:
#
# Any firmware bundle deployed must be configured to boot automatically without
# intervention. This means "PMIC_FORCE" must be set "TRUE" in the config file
# to be deployed.
#
#
# Deploy a firmware bundle with the customised "uefi.bin" installed. This
# enables an EFI network driver, allowing us to force a TFTP boot from GRUB (assuming cobbler is setup)
#
- deploy:
    namespace: recovery
    to: flasher
    images:
      recovery_image:
        url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/n1sdp-board-firmware-force-netboot.zip
        compression: zip

- deploy:
    namespace: debian
    to: tftp
    os: debian
    kernel:
      url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/debian/linux
      type: image
    ramdisk:
      url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/debian/ramdisk.img
    nfsrootfs:
      url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/debian/debian-buster-arm64-rootfs.tar.xz
      compression: xz

- boot:
    namespace: recovery
    timeout:
      minutes: 3
    method: minimal
    parameters:
      kernel-start-message: ''
    prompts: ['Cmd>']

- boot:
    namespace: uart1
    method: new_connection
    connection: uart1

- boot:
    namespace: debian
    connection-namespace: uart1
    timeout:
      minutes: 5
    method: grub
    commands: nfs
    prompts:
      - '/ # '

- test:
    namespace: debian
    timeout:
      minutes: 5
    definitions:
      - repository:
          metadata:
            format: Lava-Test Test Definition 1.0
            name: device-network
            description: '"Test device network connection"'
            os:
              - debian
            scope:
              - functional
          run:
            steps:
              - apt -q update
              - apt -q install -y iputils-ping
              - ping -c 5 10.6.43.131 || lava-test-raise "Device failed to reach a remote host"
              - hostname -I
        from: inline
        name: device-network
        path: inline/device-network.yaml

- test:
    namespace: debian
    timeout:
      minutes: 5
    definitions:
      - repository:
          metadata:
            format: Lava-Test Test Definition 1.0
            name: install-dependancies
            description: '"Install dependancies for secondary media deployment"'
            os:
              - debian
            scope:
              - functional
          run:
            steps:
              - apt-get update -q
              - apt-get install -qy bmap-tools
        from: inline
        name: install-dependancies
        path: inline/install-dependancies.yaml

- deploy:
    namespace: secondary_media
    connection-namespace: uart1
    timeout:
      minutes: 10
    to: usb
    os: oe
    images:
      image:
        url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/secondary/core-image-minimal-n1sdp.wic.gz
        compression: gz
      bmap:
        url: http://files.oss.arm.com/downloads/lava/health-checks/n1sdp/4/secondary/core-image-minimal-n1sdp.wic.bmap
    uniquify: false
    device: usb_storage_device
    writer:
      tool: /usr/bin/bmaptool
      options: copy {DOWNLOAD_URL} {DEVICE}
      prompt: 'bmaptool: info'
    tool:
      prompts: ['copying time: [0-9ms\.\ ]+, copying speed [0-9\.]+ MiB\/sec']

#
# Deploy the primary board firmware bundle (this time without the additinal
# network driver).
#
- deploy:
    namespace: recovery
    to: flasher
    images:
      recovery_image:
        url: $recovery_img_url
        compression: zip

#
# Do not verify the flash second time around as cached serial output on the
# connection will immediately match the prompt.
#
- boot:
    namespace: secondary_media
    timeout:
      minutes: 10
    method: minimal
    auto_login:
      login_prompt: '(.*)login:'
      username: root
    prompts:
      - 'root@(.*):~#'
    transfer_overlay:
      download_command: wget -S
      unpack_command: tar -C / -xzf

- test:
    namespace: secondary_media
    timeout:
      minutes: 5
    definitions:
      - repository:
          metadata:
            format: Lava-Test Test Definition 1.0
            name: linux-console-test-in-deployed-image
            description: '"Run LAVA test steps inside the deployed image"'
            os:
              - oe
            scope:
              - functional
          run:
            steps:
              - fdisk -l
              - ip addr show
              - cat /proc/cpuinfo
        from: inline
        name: linux-console-test
        path: inline/linux-console-test.yaml
EOF
