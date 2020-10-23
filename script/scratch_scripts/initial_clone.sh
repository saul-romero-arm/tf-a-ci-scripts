#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# This script is meant to be run from Jenkins to make an initial clone of the
# CI repository.
#
#  - If CI_ROOT is set, we assume that a parent job has already cloned required
#    repositories; so we skip further cloning. However, in order to prevent this
#    job from potentially cleaning up the filer workspace (which is the
#    responsibility of the parent job which did the original clone), we unset
#    the FILER_WS variable in the env file.
#
#  - Otherwise, we call clone_repos.sh to have all required repositories to be
#    cloned.
#
# Note that, since this file resides in the repository itself, a copy of this
# file must be 'wget'. I.e., any changes to to this file must be committed first
# to the CI repository master for it to take effect!

strip_var() {
        local var="$1"
        local val="$(echo "${!var}" | sed 's#^\s*\|\s*$##g')"
        eval "$var=$val"
}

strip_var CI_REFSPEC

if [ "$CI_ENVIRONMENT" ]; then
	tmpfile="$(mktemp --tmpdir="$WORKSPACE")"
	echo "$CI_ENVIRONMENT" > "$tmpfile"
	set -a
	source "$tmpfile"
	set +a
fi

if [ "$CI_ROOT" ]; then
	# We're not going to clone repos; so prevent this job from cleaning up
	# filer workspace.
	echo "FILER_WS=" > env

	# Resetting a variable doesn't seem to work on new Jenkins instance. So
	# us a different variable altogether instead.
	echo "DONT_CLEAN_WS=1" >> env

	exit 0
fi

# If no CI ref specs were explicitly specified, but was triggered from a CI
# Gerrit trigger, move to the Gerrit refspec instead so that we use the expected
# version of clone_repos.sh.
if [ -z "$CI_REFSPEC" ] && [ "$REPO_UNDER_TEST" = "trusted-firmware-ci" ] && \
		[ "$GERRIT_REFSPEC" ]; then
	CI_REFSPEC="$GERRIT_REFSPEC"
fi

# Clone CI repository and move to the refspec
git clone -q --depth 1 \
	https://gerrit.oss.arm.com/pdswinf/ci/pdcs-platforms/platform-ci

if [ "$CI_REFSPEC" ]; then
	# Only recent Git versions support fetching refs via. commit IDs.
	# However, platform slaves have been updated to a version that can do
	# this (https://jira.arm.com/browse/SSGSWINF-1426). The module load
	# commands have been commented out since.
	#
	# source /arm/tools/setup/init/bash
	# module load swdev
	# module load git/git/2.14.3

	pushd platform-ci &>/dev/null
	git fetch -q --depth 1 origin "$CI_REFSPEC"
	git checkout -q FETCH_HEAD
	echo "CI repo checked out to $CI_REFSPEC"
	popd &>/dev/null
fi

if ! platform-ci/trusted-fw/new-ci/script/clone_repos.sh; then
	echo "clone_repos.sh failed!"
	cat clone_repos.log
	exit 1
fi

# vim:set tw=80 sw=8 sts=8 noet:
