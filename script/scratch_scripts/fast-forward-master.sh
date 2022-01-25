#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Fast forward master branch with integration

set -ex

git clone ssh://$CI_BOT_USERNAME@review.trustedfirmware.org:29418/TF-A/trusted-firmware-a
cd trusted-firmware-a
git checkout master
git merge --ff-only origin/integration

# On OpenCI, disable push for now, until we're confident enough we want to do
# this automatically. See comments in https://linaro.atlassian.net/browse/TFC-223.
if echo "$JENKINS_URL" | grep -q "arm.com"; then
    git push origin master
fi

cd ..
rm -rf trusted-firmware-a
