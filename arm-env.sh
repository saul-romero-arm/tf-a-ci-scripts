#!/usr/bin/env bash
#
# Copyright (c) 2020-2021, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Environmental settings for the Arm CI infrastructure.
#

nfs_volume="/arm"
jenkins_url="http://jenkins.oss.arm.com"
tfa_downloads="http://files.oss.arm.com/downloads/tf-a"

# Source repositories.
arm_gerrit_url="gerrit.oss.arm.com"
tf_arm_gerrit_repo="ssh://$arm_gerrit_url:29418/pdcs-platforms/ap/tf-topics.git"
tftf_arm_gerrit_repo="ssh://$arm_gerrit_url:29418/trusted-firmware/tf-a-tests.git"
ci_arm_gerrit_repo="ssh://$arm_gerrit_url:29418/pdswinf/ci/pdcs-platforms/platform-ci.git"
scp_src_repo_default="${scp_src_repo_default:-http://$arm_gerrit_url/scp/firmware}"
cc_src_repo_url="${cc_src_repo_url:-https://$arm_gerrit_url/tests/lava/test-definitions.git}"
cc_src_repo_tag="${cc_src_repo_tag:-kernel-team-workflow_2019-09-20}"
scp_tools_src_repo_url="${scp_tools_src_repo_url:-http://$arm_gerrit_url/scp/tools-non-public}"
tf_for_scp_tools_src_repo_url="https://gerrit.oss.arm.com/scp/test-framework"

# If not set, the OpenCI would download the tarball from Github every time.
mbedtls_archive="${mbedtls_archive:-$tfa_downloads/mbedtls/mbedtls-2.25.0.tar.gz}"

# Arm Coverity server.
export coverity_host="${coverity_host:-coverity.cambridge.arm.com}"
export coverity_port="${coverity_port:-8443}"

# License servers for the FVP models.
license_path_list=(
    "7010@cam-lic05.cambridge.arm.com"
    "7010@cam-lic07.cambridge.arm.com"
    "7010@cam-lic03.cambridge.arm.com"
    "7010@cam-lic04.cambridge.arm.com"
)
