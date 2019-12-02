#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

ci_root="$(readlink -f "$(dirname "$0")/../..")"
source "$ci_root/utils.sh"

if ! diff $project_filer/ci-scripts/ $ci_root/script/scratch_scripts/
then
	echo "scripts in scratch folder don't match scripts in repository" >&2
	exit 1
fi
