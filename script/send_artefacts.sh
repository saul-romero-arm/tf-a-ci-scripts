#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# First parameter must be folder name
if [ $# -eq 0 ]; then
    echo "No folder name supplied."
    exit 1
fi

folder_name="$1"
archive_name="$1.tar.xz"

pushd "$workspace"

# Archive
tar -cJf "$archive_name" "$folder_name"

where="$artefacts_receiver/${TEST_GROUP:?}/${TEST_CONFIG:?}/$archive_name"
where+="?j=$JOB_NAME&b=$BUILD_NUMBER"

# Send
if wget -q --method=PUT --body-file="$archive_name" "$where"; then
    echo "$folder_name submitted to $where."
else
    echo "Error submitting $folder_name to $where."
fi

popd
