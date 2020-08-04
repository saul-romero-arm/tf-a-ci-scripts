#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

if [[ $MULTIJOB_FAILED -eq 0 ]]; then
	echo "Proceed with integration->master fast-forward merge"
	bash /arm/projectscratch/ssg/trusted-fw/ci-scripts/fast-forward-master.sh
        exit 0
else
	echo "Do not proceed with integration->master merge as sub-jobs failed"
        exit 1
fi

