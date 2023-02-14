#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
if echo "$JENKINS_URL" | grep -q "oss.arm.com"; then

export GERRIT_URL=${GERRIT_URL:-https://gerrit.oss.arm.com}
export TEST_DEFINITIONS_REPO=${TEST_DEFINITIONS_REPO:-${GERRIT_URL}/tests/lava/test-definitions.git}
export TEST_DEFINITIONS_REFSPEC=${TEST_DEFINITIONS_REFSPEC:-tools-coverage-workflow_2020-10-06}

else

export TEST_DEFINITIONS_REPO=${TEST_DEFINITIONS_REPO:-https://git.gitlab.arm.com/tooling/qa-tools.git}
export TEST_DEFINITIONS_REFSPEC=${TEST_DEFINITIONS_REFSPEC:-bug-fix-intermediate-layer}

fi
