#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Clean up filer work space if we had cloned the repository ourselves

# On Jenkins v2, $SCRATCH_OWNER will be set to the job name and build number. If
# that matches with that of the current job, then remove the scratch space.
if [ "$SCRATCH_OWNER" = "${JOB_NAME:?}-${BUILD_NUMBER:?}" ]; then
	rm -rf "${SCRATCH_OWNER_SPACE?:}"
	exit 0
fi

# On Jenkins v1, $FILER_WS will be unset if we don't need to clean up
if [ -z "$FILER_WS" ]; then
	exit 0
fi

rm -rf "$FILER_WS"
