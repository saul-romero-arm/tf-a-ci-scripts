#!/bin/bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Submit jobs to LAVA and wait until the job is complete. This script replace
# the "managed script" previously used and provide the same behavior.
#
# Required arguments:
# 1: yaml job file
# 2: a location to store output
#
# output:
# ./job_results.yaml
# ${SAVE_OUTPUT}/job_output.log

set -e

source "$CI_ROOT/utils.sh"

export XDG_CONFIG_HOME="${WORKSPACE}"

JOB_FILE="$1"
SAVE_OUTPUT="$2"

LAVA_HOST="${LAVA_HOST:-lava.oss.arm.com}"
LAVA_USER="$3"
LAVA_TOKEN="$4"
LAVA_URL="https://${LAVA_HOST}"

if [ ! -f "${JOB_FILE}" ]; then
	echo "error: LAVA job file does not exist: ${JOB_FILE}"
	exit 1
fi

# Install lavacli with fixes
virtualenv -p $(which python3) venv
source venv/bin/activate
pip install -q lavacli

# Configure lavacli
lavacli identities add \
--username $LAVA_USER \
--token $LAVA_TOKEN \
--uri ${LAVA_URL}/RPC2 \
default

# Submit a job using lavacli
JOB_ID=$(lavacli jobs submit ${JOB_FILE})
if [ -z "$JOB_ID" ] ; then
	echo "Couldn't submit. Stopping."
	exit 1
fi

echo "Job url: https://lava.oss.arm.com/scheduler/job/$JOB_ID"

# Wait for the job to finish
lavacli jobs wait $JOB_ID

# Output to the specified directory before uploading artefacts
mkdir -p "${SAVE_OUTPUT}"
curl https://lava.oss.arm.com/scheduler/job/$JOB_ID/log_file/plain > "${SAVE_OUTPUT}/job_output.log"
cp ${SAVE_OUTPUT}/job_output.log $workspace/artefacts

# Send file(s) to artefacts receiver
if upon "$jenkins_run" && upon "$artefacts_receiver" && [ -d "${SAVE_OUTPUT}" ]; then
    source "$CI_ROOT/script/send_artefacts.sh" "${SAVE_OUTPUT}"
fi

# Get results
lavacli results $JOB_ID --yaml > "job_results.yaml"

# Exit virtualenv
deactivate
