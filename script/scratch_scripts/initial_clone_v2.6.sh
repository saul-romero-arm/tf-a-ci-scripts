#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This script is meant to be run from Jenkins to make an initial clone of the
# CI repository.
#
#  - If CI_SCRATCH is set, we assume that a parent job has already cloned
#    required repositories; so we skip further cloning.
#
#  - Otherwise, we call clone_repos.sh to have all required repositories to be
#    cloned.
#
# Note that, since this file resides in the repository itself, a copy of this
# file must be 'wget'. I.e., any changes to to this file must be committed first
# to the CI repository master for it to take effect!

set -e

arm_gerrit_url="gerrit.oss.arm.com"
tforg_gerrit_url="review.trustedfirmware.org"
ci_url="${CI_SRC_REPO_URL:-https://$tforg_gerrit_url/ci/tf-a-ci-scripts}"
gerrit_server="tforg"

if [ "$ci_url" == *${arm_gerrit_url}* ];then
        gerrit_server="arm"
fi

strip_var() {
	local var="$1"
	local val="$(echo "${!var}" | sed 's#^\s*\|\s*$##g')"
	eval "$var=$val"
}

set_ci_root() {
	ci_root=`pwd`/"trusted-firmware-ci"
	CI_ROOT=$ci_root
}

strip_var CI_REFSPEC

if [ ! -z $PROJECT ]; then
	export REPO_UNDER_TEST=`basename $PROJECT`
	echo "REPO_UNDER_TEST is blank, but PROJECT is set, setting REPO_UNDER_TEST based on PROJECT"
	echo "REPO_UNDER_TEST=$REPO_UNDER_TEST"
	echo "REPO_UNDER_TEST=$REPO_UNDER_TEST" >> env
fi

# For jobs triggered by Gerrit, obtain REPO_UNDER_TEST, TF_SRC_REPO_URL
# and TFTF_SRC_REPO_URL (if not set explicitly) from Gerrit Environment
# variables.

if [ "$GERRIT_REFSPEC" ]; then

	if [ -z $REPO_UNDER_TEST ]; then
		if [ $GERRIT_PROJECT == "pdcs-platforms/ap/tf-topics" ] || [ $GERRIT_PROJECT == "TF-A/trusted-firmware-a" ]; then
			export REPO_UNDER_TEST="trusted-firmware"
			echo "REPO_UNDER_TEST is blank, setting REPO_UNDER_TEST based on GERRIT_PROJECT"

		elif [ $GERRIT_PROJECT == "trusted-firmware/tf-a-tests" ] || [ $GERRIT_PROJECT == "TF-A/tf-a-tests" ]; then
			export REPO_UNDER_TEST="trusted-firmware-tf"
			echo "REPO_UNDER_TEST is blank, setting REPO_UNDER_TEST based on GERRIT_PROJECT"

		elif [ $GERRIT_PROJECT == "pdswinf/ci/pdcs-platforms/platform-ci" ] || [ $GERRIT_PROJECT == "ci/tf-a-ci-scripts" ]; then
			export REPO_UNDER_TEST="trusted-firmware-ci"
			echo "REPO_UNDER_TEST is blank, setting REPO_UNDER_TEST based on GERRIT_PROJECT"
		fi
	fi

	if [ -z $TF_SRC_REPO_URL ] && [ $REPO_UNDER_TEST == "trusted-firmware" ]; then
		export TF_SRC_REPO_URL="https://$GERRIT_HOST/$GERRIT_PROJECT"
	fi

	if [ -z $TFTF_SRC_REPO_URL ] && [ $REPO_UNDER_TEST == "trusted-firmware-tf" ]; then
		export TFTF_SRC_REPO_URL="https://$GERRIT_HOST/$GERRIT_PROJECT"
	fi
fi

if [ "$CI_ENVIRONMENT" ]; then
	tmpfile="$(mktemp --tmpdir="$WORKSPACE")"
	echo "$CI_ENVIRONMENT" | tr ' ' '\n' > "$tmpfile"
	set -a
	source "$tmpfile"
	set +a
fi

if [ "$CI_SCRATCH" ]; then
	if [ ! -d "$CI_SCRATCH" ]; then
		echo "\$CI_SCRATCH is stale; ignored."
	else
		# Copy environment and parameter file from scratch to this job's
		# workspace
		cp "$CI_SCRATCH/env" .
		cp "$CI_SCRATCH/env.param" .
		find "$CI_SCRATCH" -name "*.data" -exec cp -t . '{}' +

		exit 0
	fi
fi

# If no CI ref specs were explicitly specified, but was triggered from a CI
# Gerrit trigger, move to the Gerrit refspec instead so that we use the expected
# version of clone_repos.sh.
if [ -z "$CI_REFSPEC" ] && [ "$REPO_UNDER_TEST" = "trusted-firmware-ci" ] && \
		[ "$GERRIT_REFSPEC" ]; then
	export CI_REFSPEC="$GERRIT_REFSPEC"
fi

# Clone CI repository and move to the refspec
if [ ! -d "trusted-firmware-ci" ]
then
git clone -q --depth 1 \
	--reference /arm/projectscratch/ssg/trusted-fw/ref-repos/trusted-firmware-ci \
	$ci_url trusted-firmware-ci
else
	pushd trusted-firmware-ci
	git fetch
	git checkout origin/master
	popd
fi

set_ci_root
# Set CI_ROOT as a fallback
echo "CI_ROOT=$ci_root" >> env

if [ "$CI_REFSPEC" ]; then
	# Only recent Git versions support fetching refs via. commit IDs.
	# However, platform slaves have been updated to a version that can do
	# this (https://jira.arm.com/browse/SSGSWINF-1426). The module load
	# commands have been commented out since.
	#
	# source /arm/tools/setup/init/bash
	# module load swdev
	# module load git/git/2.14.3

	# Translate refspec if supported
	if [ -x "$ci_root/script/translate_refspec.py" ]; then
		CI_REFSPEC="$("$ci_root/script/translate_refspec.py" \
				-p trusted-firmware-ci -s $gerrit_server "$CI_REFSPEC")"
	fi

	pushd trusted-firmware-ci &>/dev/null
	git fetch -q --depth 1 origin "$CI_REFSPEC"
	git checkout -q FETCH_HEAD
	echo
	echo "Initial CI repo checked out to '$CI_REFSPEC'."
	popd &>/dev/null
fi

if [ "$ci_only" ]; then
	exit 0
fi

if echo "$-" | grep -q "x"; then
	minus_x="-x"
fi

if ! bash $minus_x "$ci_root/script/clone_repos.sh"; then
	echo "clone_repos.sh failed!"
	cat clone_repos.log
	exit 1
fi

# vim:set tw=80 sw=8 sts=8 noet:
