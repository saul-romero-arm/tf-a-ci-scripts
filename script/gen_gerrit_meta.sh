#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate Gerrit-related metadata for LAVA job definitions. This is
# include file is supposed to be sourced from gen_*_yaml.sh files.


if [ -n "${GERRIT_CHANGE_NUMBER}" ]; then
    gerrit_url="https://review.trustedfirmware.org/c/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
elif [ -n "${GERRIT_REFSPEC}" ]; then
    gerrit_url=$(echo ${GERRIT_REFSPEC} |  awk -F/ '{print "https://review.trustedfirmware.org/c/" $4 "/" $5}')
fi

if [ -n "${gerrit_url}" ]; then
    gerrit_meta="\
  gerrit_url: ${gerrit_url}"
fi
