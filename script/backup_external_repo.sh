#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Make a backup of the following repositories on Github:
# - arm-trusted-firmware-private.git
# - arm-trusted-firmware-private.wiki.git
# - tf-issues.git
#
# Also backup the following repositories from review.trustedfirmware.org:
# - trusted-firmware-a.git
# - tf-a-tests.git

set -e

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"

backup_dir="${BACKUP_DIR:-/arm/ref/pd/pdsw/external-repo-backup}"


initial_clone() {
	local repo_url="${1:?}"
	local repo_dir="${2:?}"
	local repo_name="$(basename $repo_dir)"
	local s_before s_after s_diff

	s_before="$(date +%s)"

	echo
	echo "Cloning repository $repo_name..."

	git clone --quiet --mirror "$repo_url" "$repo_dir"

	pushd "$repo_dir"
	git show --quiet | sed 's/^/  > /g'
	popd

	s_after="$(date +%s)"
	let "s_diff = $s_after - $s_before" || true
	echo "Cloned in $s_diff seconds."
	echo
}

update_repo() {
	local repo_dir="${1:?}"
	local repo_name="$(basename $repo_dir)"
	local s_before s_after s_diff

	pushd "$repo_dir"

	s_before="$(date +%s)"

	echo
	echo "Updating repo $repo_name..."

	git gc --quiet
	git remote update --prune
	git show --quiet | sed 's/^/  > /g'

	s_after="$(date +%s)"
	let "s_diff = $s_after - $s_before" || true
	echo "Updated in $s_diff seconds."
	echo

	popd
}

get_repo_url() {
    local url_var="${1:?}"
    local repo_location="${2:?}"
    local repo_name="${3:?}"

    case "$repo_location" in
    "github")
	if upon "$anonymous"; then
	    eval $url_var="https://github.com/ARM-software/$repo_name"
	else
	    GITHUB_USER="${GITHUB_USER:-arm-tf-bot}"
	    GITHUB_PASSWORD="${GITHUB_PASSWORD:?}"
	    eval $url_var="https://$GITHUB_USER:$GITHUB_PASSWORD@github.com/ARM-software/$repo_name"
	fi
	;;

    "tf.org")
	if not_upon "$anonymous"; then
	    echo "Authenticated access to repo $repo_name not supported."
	    exit 1
	fi
	eval $url_var="https://review.trustedfirmware.org/TF-A/$repo_name"
	;;

    *)
	echo "Unsupported repository location: $repo_location."
	exit 1
	;;
    esac
}

backup_repo() {
	local repo_location="${1:?}"
	local repo_name="${2:?}"
	local repo_dir="${3:-$repo_location/$repo_name}"

	if [ ! -d "$repo_dir" ]; then
	    local repo_url
	    get_repo_url "repo_url" "$repo_location" "$repo_name"
	    initial_clone "$repo_url" "$repo_dir"
	else
	    update_repo "${repo_dir:?}"
	fi
}


cd "$backup_dir"

# Private repositories. Need arm-tf-bot credentials for authentication.
anonymous=0 backup_repo "github" "arm-trusted-firmware-private.git"
anonymous=0 backup_repo "github" "arm-trusted-firmware-private.wiki.git"

# Public repositories. Anonymous access is allowed.
anonymous=1 backup_repo "github" "tf-issues.git"

anonymous=1 backup_repo "tf.org" "trusted-firmware-a.git"
anonymous=1 backup_repo "tf.org" "tf-a-tests.git"
