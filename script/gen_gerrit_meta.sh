#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate Gerrit-related metadata for LAVA job definitions. This is
# include file is supposed to be sourced from gen_*_yaml.sh files.

if [ -n "${GERRIT_REFSPEC}" ]; then
    gerrit_url=$(echo ${GERRIT_REFSPEC} |  awk -F/ '{print "https://review.trustedfirmware.org/c/" $4 "/" $5}')

    gerrit_meta="\
  gerrit_project: ${GERRIT_PROJECT}
  gerrit_branch: ${GERRIT_BRANCH}
  gerrit_url: ${gerrit_url}"
fi
