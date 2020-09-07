#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a YAML file in order to dispatch Juno runs on LAVA. Note that this
# script would produce a meaningful output when run via. Jenkins
#
# $bin_mode must be set. This script outputs to STDOUT

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"
source "$ci_root/juno_utils.sh"

get_recovery_image_url() {
	local build_job="tf-build"
	local bin_mode="${bin_mode:?}"

	if upon "$jenkins_run"; then
		echo "$jenkins_url/job/$JOB_NAME/$BUILD_NUMBER/artifact/artefacts/$bin_mode/juno_recovery.zip"
	else
		echo "file://$workspace/artefacts/$bin_mode/juno_recovery.zip"
	fi
}

bootloader_prompt="${bootloader_prompt:-juno#}"
recovery_img_url="${recovery_img_url:-$(get_recovery_image_url)}"
nfs_rootfs="${nfs_rootfs:-$juno_rootfs_url}"
linux_prompt="${linux_prompt:-root@(.*):~#}"

# Allow running juno tests on specific revision(r0/r1/r2).
juno_revision="${juno_revision:-}"
if [ ! -z "$juno_revision" ]; then
        tags="tags:"
        juno_revision="- ${juno_revision}"
else
        tags=""
fi

cat <<EOF
device_type: juno
job_name: tf-juno

context:
  bootloader_prompt: $bootloader_prompt

$tags
$juno_revision

timeouts:
  # Global timeout value for the whole job.
  job:
    minutes: 30
  # Unless explicitly overwritten, no single action should take more than
  # 10 minutes to complete.
  action:
    minutes: 10

priority: medium
visibility: public

actions:

- deploy:
    namespace: recovery
    to: vemsd
    recovery_image:
      url: $recovery_img_url
      compression: zip

- deploy:
    namespace: target
    to: nfs
    os: debian
    nfsrootfs:
      url: $nfs_rootfs
      compression: gz

- boot:
    # Drastically increase the timeout for the boot action because of the udev
    # issues when using TF build config "juno-all-cpu-reset-ops".
    # TODO: Should increase the timeout only for this TF build config, not all!
    timeout:
      minutes: 15
    namespace: target
    connection-namespace: recovery
    method: u-boot
    commands: norflash
    auto-login:
      login_prompt: 'login:'
      username: root
    prompts:
    - $linux_prompt
EOF
