#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Generate test report
if [ "$CI_ROOT" ]; then
	# Gather Coverity scan summary if it was performed as part of this job
	if [ "$(find -maxdepth 1 -name '*coverity*.test' -type f | wc -l)" != 0 ]; then
		if ! "$CI_ROOT/script/coverity_summary.py" "$BUILD_URL" > coverity.data; then
			rm -f coverity.data
		fi
	fi

	# set proper jobs names for test generation report script
	if echo "$JENKINS_URL" | grep -q "arm.com"; then
		worker_job="${worker_job:-tf-worker}"
		lava_job="${lava_job:-tf-build-for-lava}"
	else
		# ${TRIGGERED_JOB_NAMES} has hyphens replaced with underscores.
		# As we know that we use hyphen convention, translate it back.
		triggered_job=$(echo ${TRIGGERED_JOB_NAMES} | tr "_" "-")
		worker_job="${worker_job:-${triggered_job}}"
		lava_job="${lava_job:-${triggered_job}}"
        fi

	"$CI_ROOT/script/gen_test_report.py" \
		--job "${worker_job}" \
		--build-job "${lava_job}" \
		--meta-data clone.data \
		--meta-data override.data \
		--meta-data inject.data \
		--meta-data html:coverity.data \
		|| true

	# TODO: Open CI does not (yet) support the merge of code coverage report into main
	# report, so for the moment condition this task under the Jenkins Arm
	# environment.
	if echo "$JENKINS_URL" | grep -q "arm.com"; then
	    source $CI_ROOT/script/gen_merge_report.sh "${WORKSPACE}/report.json" \
		   "${WORKSPACE}/report.html"
	fi
fi
