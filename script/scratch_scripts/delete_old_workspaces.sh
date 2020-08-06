#!/usr/bin/env bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Cleanup work spaces older than a day
cd /arm/projectscratch/ssg/trusted-fw/ci-workspace
find -maxdepth 1 \( -not -name . -a -mtime +1 \) -exec rm -rf '{}' +
