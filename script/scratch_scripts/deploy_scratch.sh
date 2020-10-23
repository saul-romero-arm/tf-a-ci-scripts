#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
ci_root="$(readlink -f "$(dirname "$0")/../..")"
source "$ci_root/utils.sh"

if ! ls $project_filer/ci-scripts/
then
	echo "make sure /arm is mounted, if it is not, it can be mounted with the following command:" >&2
	echo "sudo sshfs [USER]@login1.euhpc2.arm.com:/arm /arm -o allow_other,reconnect" >&2
	echo "note that the euhpc and euhpc2 have different /arm mounts" >&2
	exit 1
fi

COMMAND="cp $ci_root/script/scratch_scripts/* $project_filer/ci-scripts/"
FILES=`ls -al "$ci_root"/script/scratch_scripts/*`

echo "files to be copied:"
echo "$FILES"
echo ""
echo "####DANGER### POTENTIAL FOR DAMAGE, CHECK THIS COMMAND"
echo "command to be run: \"$COMMAND\""
read -p "Run this command [Y/n]: "
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	eval "$COMMAND"
fi
