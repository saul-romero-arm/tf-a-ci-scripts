#!/usr/bin/env bash
#
# Copyright (c) 2020-2022, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Fast forward master branch with integration

set -ex

# Use a directory which won't clash with a r/o clone made for building.
clone_dir=trusted-firmware-a-for-update

git clone ssh://$CI_BOT_USERNAME@review.trustedfirmware.org:29418/TF-A/trusted-firmware-a ${clone_dir}
cd ${clone_dir}
git checkout master
git merge --ff-only origin/integration

# On OpenCI, disable push for now, until we're confident enough we want to do
# this automatically. See comments in https://linaro.atlassian.net/browse/TFC-223.
if echo "$JENKINS_URL" | grep -q "arm.com"; then
    git push origin master
fi

cd ..
rm -rf ${clone_dir}
