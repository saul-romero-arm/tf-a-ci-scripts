#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Fast forward master branch with integration

set -e

git clone ssh://$CI_BOT_USERNAME@review.trustedfirmware.org:29418/TF-A/trusted-firmware-a
cd trusted-firmware-a
git checkout master
git merge --ff-only origin/integration
git push origin master
cd ..
rm -rf trusted-firmware-a
