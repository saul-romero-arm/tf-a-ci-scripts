#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

ci_root="$(readlink -f "$(dirname "$0")/../..")"
source "$ci_root/utils.sh"

declare -A repo_urls=(
[pdcs-platforms/ap/tf-topics]="name=trusted-firmware url=$tf_src_repo_url"
[trusted-firmware/tf-a-tests]="name=trusted-firmware-tf url=$tftf_src_repo_url"
[pdswinf/ci/pdcs-platforms/platform-ci]="name=trusted-firmware-ci url=$tf_ci_repo_url"
)

project="${GERRIT_PROJECT:-$PROJECT}"
eval "${repo_urls[$project]?}"
ref_dir="$project_filer/ref-repos/$name"

# Create/update reference repository.
mkdir -p "$ref_dir"
if [ ! -d "$ref_dir" ]; then
	# Clone afresh
	mkdir -p "$ref_dir"
	git clone -q "$url" "$ref_dir"
else
	# Update master
	cd "$ref_dir"
	git fetch -q origin master
	git reset -q --hard origin/master
fi

echo "Updated $name"
