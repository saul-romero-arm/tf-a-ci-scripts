#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# $1 = git remote human readable name
# $2 = git remote URL
sync_repo()
{
	local result
	echo Pushing to $1...
	git push $2 master
	result=$?
	if [ $result != 0 ]
	then
		echo Pushing to $1 FAILED!
	else
		echo Pushing to $1 SUCCEEDED!
	fi
	return $result
}

# exit if anything fails
set -e

source "$CI_ROOT/utils.sh"

if [ ! -d "trusted-firmware-a" ]
then
	# Fresh clone
	echo Cloning from trustedfirmware.org...
	git clone $tf_src_repo_url
else
	echo Using existing repo...
fi

echo Pulling from trustedfirmware.org...
cd trusted-firmware-a
git remote update --prune
git checkout master
git merge --ff-only origin/master

# stop exiting automatically
set +e

sync_repo GitHub https://$GH_USER:$GH_PASSWORD@github.com/ARM-software/arm-trusted-firmware.git
github=$?
sync_repo "internal Arm Gerrit" $tf_arm_gerrit_repo
gerrit=$?

if [ $github != 0 -o $gerrit != 0 ]
then
	exit 1
fi
