#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Submit jobs to LAVA and wait until the job is complete. This script replace
# the "managed script" previously used and provide the same behavior.
#
# Required arguments:
# 1: yaml job file
# 2: flag whether to save output, true/false, defaults to false
#
# output:
# job_results.yaml
# job_output.log if save output = true

set -e

JOB_FILE="$1"
SAVE_OUTPUT="$2"

LAVA_HOST=
LAVA_USER=
LAVA_TOKEN=
LAVA_URL=

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

if [ "${SAVE_OUTPUT}" = "true" ] ; then
	lavacli jobs logs $JOB_ID > job_output.log
fi

# Get results
lavacli results $JOB_ID --yaml > job_results.yaml

# Exit virtualenv
deactivate
