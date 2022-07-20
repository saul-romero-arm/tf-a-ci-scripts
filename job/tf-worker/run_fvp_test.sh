#!/usr/bin/env bash
#
# Copyright (c) 2019-2022, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e

# Build
export COVERAGE_ON=$(echo "$RUN_CONFIG" | grep -v 'aarch32' | grep -qE 'bmcov' && echo 1 || echo 0)
if [ $COVERAGE_ON -eq 1 ]; then
	source "$CI_ROOT/script/build_bmcov.sh"
fi

"$CI_ROOT/script/build_package.sh"


if [ "$skip_runs" ]; then
	exit 0
fi

# Execute test locally for FVP configs
if [ "$RUN_CONFIG" != "nil" ] && echo "$RUN_CONFIG" | grep -iq '^fvp'; then
	"$CI_ROOT/script/run_package.sh"
	if [ $COVERAGE_ON -eq 1 ]; then
		ELF_FOLDER=""
		DEBUG_FOLDER=${artefacts}/debug
		RELEASE_FOLDER=${artefacts}/release
		if ls "${DEBUG_FOLDER}/"*.elf &> /dev/null;then
			export ELF_FOLDER=$DEBUG_FOLDER
		elif ls "${RELEASE_FOLDER}/"*.elf &> /dev/null;then
			export ELF_FOLDER=$RELEASE_FOLDER
		else
			# If elf files are not present, report can't be produced
			echo "ELF files not present, aborting reports..."
			exit 0
		fi
		export OUTDIR=${WORKSPACE}/html
		test_config=${TEST_CONFIG}
		if [ -n "$CC_SCP_REFSPEC" ]; then #SCP
			export JENKINS_SOURCES_WORKSPACE="${scp_root:-$workspace}"
			if grep -q "fvp-linux.sgi" <<< "$test_config"; then
				export LIST_OF_BINARIES=${LIST_OF_BINARIES:-"scp_ram scp_rom mcp_rom mcp_ram"}
			fi
			export OBJDUMP="$(which 'arm-none-eabi-objdump')"
			export READELF="$(which 'arm-none-eabi-readelf')"
			export REPO=SCP
		else # TF-A
			export JENKINS_SOURCES_WORKSPACE="${tf_root:-$workspace}"
			export LIST_OF_BINARIES=${LIST_OF_BINARIES:-"bl1 bl2 bl31"}
			export OBJDUMP="$(which 'aarch64-none-elf-objdump')"
			export READELF="$(which 'aarch64-none-elf-readelf')"
			export REPO=TRUSTED_FIRMWARE
		fi
		echo "Toolchain:$OBJDUMP"

		mkdir -p ${OUTDIR}
		sync
		sleep 5 #wait for trace files to be written
		if [ $(ls -1 ${DEBUG_FOLDER}/${trace_file_prefix}-* 2>/dev/null | wc -l) != 0 ]; then
			export TRACE_FOLDER=${DEBUG_FOLDER}
		elif [ $(ls -1 ${RELEASE_FOLDER}/${trace_file_prefix}-* 2>/dev/null | wc -l) != 0 ]; then
			export TRACE_FOLDER=${RELEASE_FOLDER}
		else
			echo "Trace files not present, aborting reports..."
			exit 0
		fi
		export REPORT_TITLE="Coverage Summary Report [Build:${BUILD_NUMBER}]"
		# launch intermediate layer script
		export CONFIG_JSON=${OUTDIR}/config_file.json
		export OUTPUT_JSON=${OUTDIR}/output_file.json
		export CSOURCE_FOLDER=source
		export DEBUG_ELFS=${DEBUG_ELFS:-True}
		prepare_json_configuration "${LIST_OF_BINARIES}" "${JENKINS_SOURCES_WORKSPACE}"
		echo "Executing intermediate_layer.py ..."
		python ${BMCOV_REPORT_FOLDER}/intermediate_layer.py --config-json "${CONFIG_JSON}"
		ver_py=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
		if [ "$ver_py" = "27" ]; then
			python ${BMCOV_REPORT_FOLDER}/gen-coverage-report.py --config ${BMCOV_REPORT_FOLDER}/config_atf.py \
			--prefix_workspace "$JENKINS_SOURCES_WORKSPACE"
		else
			echo "Python 2.7 is required for producing Bmcov reports"
		fi
		chmod 775 ${BMCOV_REPORT_FOLDER}/branch_coverage/branch_coverage.sh
		echo "Running branch coverage..."
		branch_folder=${OUTDIR}/lcov_report
		mkdir -p ${branch_folder}
		pushd ${BMCOV_REPORT_FOLDER}/branch_coverage
		. branch_coverage.sh --workspace ${JENKINS_SOURCES_WORKSPACE} --json-path ${OUTPUT_JSON} --outdir ${branch_folder}
		popd
		export OUTDIR=${WORKSPACE}/html
		# prepare static (Jenkins) and dynamic (python server) pages
		prepare_html_pages
	fi
fi
