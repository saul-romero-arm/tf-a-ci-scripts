#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

source "$CI_ROOT/utils.sh"

# Clone TF-A Tests repo from tf.org.
if [ ! -d "tf-a-tests" ]; then
	git clone --origin tforg $tftf_src_repo_url
	cd tf-a-tests
	git remote add arm $tftf_arm_gerrit_repo
else
	cd tf-a-tests
fi

# Get the latest updates from the master branch on tf.org.
git remote update --prune
git checkout master
git merge --ff-only tforg/master

# Push updates to Arm internal Gerrit.
git push arm master
