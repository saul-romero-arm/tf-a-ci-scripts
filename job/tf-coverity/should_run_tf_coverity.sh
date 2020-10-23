#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This script checks if the current patch modifies scripts which run
# Coverity Online Scan in tf-coverity jenkins job.

set -e

cd $CI_ROOT
current_commit=$(git rev-parse --short HEAD)
modified_files=$(git diff-tree --no-commit-id --name-only -r $current_commit)

hit=$(echo $modified_files|grep "script/tf-coverity/"|wc -l)
cd -

if [ $hit -gt 0 ]; then
	echo "Coverity scripts modified in this patch. tf-coverity will be triggered"
	exit 0
fi

echo "No coverity scripts modified"
exit 1
