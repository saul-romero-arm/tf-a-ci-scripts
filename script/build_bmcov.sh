#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -e
source "$CI_ROOT/utils.sh"

prepare_json_configuration() {
    set +e
    elf_files="${1:-$LIST_OF_BINARIES}"
    jenkins_sources="${2:-$JENKINS_SOURCES_WORKSPACE}"
    elf_array=($elf_files)
    elf=""
    for index in "${!elf_array[@]}"
    do
        if [ "${DEBUG_ELFS}" = "True" ]; then
            cp "${ELF_FOLDER}/${elf_array[$index]}.elf" ${OUTDIR}/.
        fi
        read -r -d '' elf << EOM
${elf}
                {
                    "name": "${ELF_FOLDER}/${elf_array[$index]}.elf",
                    "traces": [
                                "${TRACE_FOLDER}/${trace_file_prefix:-covtrace}-*.log"
                              ]
                }
EOM
    if [ $index -lt $((${#elf_array[@]} - 1)) ];then
        elf="${elf},"
    fi
    done
    if [ "$REPO" = "SCP" ]; then
        read -r -d '' sources << EOM
                [
                    {
                    "type": "git",
                    "URL":  "$CC_SCP_URL",
                    "COMMIT": "$CC_SCP_COMMIT",
                    "REFSPEC": "$CC_SCP_REFSPEC",
                    "LOCATION": "scp"
                    },
                    {
                    "type": "git",
                    "URL":  "$CC_CMSIS_URL",
                    "COMMIT": "$CC_CMSIS_COMMIT",
                    "REFSPEC": "$CC_CMSIS_REFSPEC",
                    "LOCATION": "scp/contrib/cmsis/git"
                    }
                ]
EOM
    elif [ "$REPO" = "TRUSTED_FIRMWARE" ]; then
        read -r -d '' sources << EOM
                [
                    {
                    "type": "git",
                    "URL":  "$CC_TRUSTED_FIRMWARE_URL",
                    "COMMIT": "$CC_TRUSTED_FIRMWARE_COMMIT",
                    "REFSPEC": "$CC_TRUSTED_FIRMWARE_REFSPEC",
                    "LOCATION": "trusted_firmware"
                    },
                    {
                    "type": "http",
                    "URL":  "$mbedtls_archive",
                    "COMPRESSION": "xz",
                    "EXTRA_PARAMS": "--strip-components=1",
                    "LOCATION": "mbedtls"
                    }
                ]
EOM
    else
        sources=""
    fi
metadata="\"BUILD_CONFIG\": \"${BUILD_CONFIG}\", \"RUN_CONFIG\": \"${RUN_CONFIG}\""
cat <<EOF > "${CONFIG_JSON}"
{
    "configuration":
        {
        "remove_workspace": true,
        "include_assembly": true
        },
    "parameters":
        {
        "sources": $sources,
        "workspace": "${jenkins_sources}",
        "output_file": "${OUTPUT_JSON}",
        "metadata": {$metadata}
        },
    "elfs": [
            ${elf}
        ]
}
EOF
set -e
}

prepare_html_pages() {
    pushd ${OUTDIR}
    cp ${BMCOV_REPORT_FOLDER}/reporter_cc.py ${OUTDIR}/.
    if [ "${DEBUG_ELFS}" = "True" ]; then
        cp "${TRACE_FOLDER}/${trace_file_prefix}"* ${OUTDIR}/.
    fi
    # to be run on the user locally
    cat <<EOF > "server.sh"
#!/usr/bin/env bash

echo "Running server..."
type -a firefox || (echo "Please install Firefox..." && exit 1)
type -a python3 || (echo "Please install python3..." && exit 1)

python - << EOT
import os
import reporter_cc

output_file = os.getenv('OUTPUT_JSON', 'output_file.json')
source_folder = os.getenv('CSOURCE_FOLDER', 'source')
r = reporter_cc.ReportCC(output_file)
r.clone_repo(source_folder)
EOT
(sleep 2; firefox --new-window http://localhost:8081) &
python3 -m http.server 8081
EOF
    chmod 777 server.sh
    zip -r server_side.zip *
    popd
}

PVLIB_HOME=${PVLIB_HOME:-$warehouse/SysGen/PVModelLib/$model_version/$model_build/external}
echo "Building Bmcov for code coverage..."
source "$CI_ROOT/script/test_definitions.sh"
export BMCOV_FOLDER="${BMCOV_FOLDER:-$workspace/test-definitions/scripts/tools/code_coverage/fastmodel_baremetal/bmcov}"
pushd "${workspace}"
git clone "${TEST_DEFINITIONS_REPO}" -b "${TEST_DEFINITIONS_REFSPEC}"
popd
pushd "${BMCOV_FOLDER}"
export MODEL_PLUGIN_FOLDER="${BMCOV_FOLDER}"/model-plugin
if [ -n "$(find "$warehouse" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
    echo "$warehouse not mounted. Falling back to pre-built plugins.."
    folder="http://files.oss.arm.com/downloads/tf-a/coverage-plugin"
    wget -q ${folder}/{CoverageTrace.so,CoverageTrace.o,PluginUtils.o} \
    -P "${MODEL_PLUGIN_FOLDER}"
 else
    make -C model-plugin PVLIB_HOME="$PVLIB_HOME"
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MODEL_PLUGIN_FOLDER
export trace_file_prefix=covtrace
export BMCOV_REPORT_FOLDER="${BMCOV_FOLDER}"/report
export coverage_trace_plugin="${MODEL_PLUGIN_FOLDER}"/CoverageTrace.so
popd
