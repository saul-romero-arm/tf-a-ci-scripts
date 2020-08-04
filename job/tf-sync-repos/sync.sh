#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Push the updated master from local to the selected remote
#
# $1 = git remote human readable name
# $2 = git remote URL
sync_repo()
{
	local result

	echo Pushing to "$1"...
	git push --tags $2 master
	result=$?
	if [ $result != 0 ]
	then
		echo Pushing to $1 FAILED!
	else
		echo Pushing to $1 SUCCEEDED!
	fi
	return $result
}

# Clone the selected repo from tf.org
#
# Some variables utilised inside this function come from utils.sh
#
# $1 = repo to clone
clone_repo()
{
	local repo_url
	local repo_name

	case $1 in
		trusted-firmware-a)
			repo_url=$tf_src_repo_url
			repo_name="TF-A"
			;;
		tf-a-tests)
			repo_url=$tftf_src_repo_url
			repo_name="TF-A-Tests"
			;;
		*)
			echo "ERROR: Unknown repo to be cloned. sync.sh failed!"
			exit 1
			;;
	esac

	# Check if the repo clone exists in the job's workspace
	if [ ! -d $1 ]
	then
		# Fresh clone
		echo Cloning $repo_name from trustedfirmware.org...
		git clone $repo_url
	else
		echo Will use existing repo for "$repo_name"...
	fi
}

# Pull changes from tf.org to the local repo
#
# $1 = repo to update. It must be the same with the directory name
pull_changes()
{
	cd $1
	echo Pulling $1 from trustedfirmware.org...
	git remote update --prune
	git checkout master
	git merge --ff-only origin/master
	cd - > /dev/null
}

# exit if anything fails
set -e

# Source this file to get TF-A and TF-A-Tests repo URLs
source "$CI_ROOT/utils.sh"

clone_repo trusted-firmware-a
clone_repo tf-a-tests

pull_changes trusted-firmware-a
pull_changes tf-a-tests

# stop exiting automatically
set +e

# Update TF-A remotes
cd trusted-firmware-a
sync_repo GitHub https://$GH_USER:$GH_PASSWORD@github.com/ARM-software/arm-trusted-firmware.git
github=$?
sync_repo "internal TF-A Gerrit" $tf_arm_gerrit_repo
tfa_gerrit=$?

# Update TF-A-Tests
cd ../tf-a-tests
sync_repo "internal TF-A-Tests Gerrit" $tftf_arm_gerrit_repo
tftf_gerrit=$?

if [ $github != 0 -o $tfa_gerrit != 0 -o $tftf_gerrit != 0 ]
then
	exit 1
fi
