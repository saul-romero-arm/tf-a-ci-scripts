#!/bin/bash
#
# Copyright (c) 2021-2022 BUGSENG srl. All rights reserved.
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

# Stop immediately if any executed command has exit status different from 0.
set -ex

usage() {
    echo "Usage: analyze.sh CONF" 1>&2
    echo "  where CONF is the build configuration id passed to build.sh" 1>&2
}

if [ $# -ne 1 ]
then
    usage
    exit 1
fi

TF_CONFIG="$1"

# Directory where this script resides.
SCRIPT_DIR="$(cd "$(dirname "$0")" ; echo "${PWD}")"

. ${SCRIPT_DIR}/analyze_common.sh

# Directory where to put all ECLAIR output and temporary files.
ECLAIR_OUTPUT_DIR="${WORKSPACE}/ECLAIR/out"

# ECLAIR binary data directory and workspace.
export ECLAIR_DATA_DIR="${ECLAIR_OUTPUT_DIR}/.data"
# ECLAIR workspace.
export ECLAIR_WORKSPACE="${ECLAIR_DATA_DIR}/eclair_workspace"
# Destination file for the ECLAIR diagnostics.
export ECLAIR_DIAGNOSTICS_OUTPUT="${ECLAIR_OUTPUT_DIR}/DIAGNOSTICS.txt"

# Erase and recreate the output directory and the data directory.
rm -rf "${ECLAIR_OUTPUT_DIR}"
mkdir -p "${ECLAIR_DATA_DIR}"

(
  # Perform the build (from scratch) in an ECLAIR environment.
  "${ECLAIR_BIN_DIR}/eclair_env"                   \
      "-eval_file='${SCRIPT_DIR}/MISRA_C_2012_selection.ecl'" \
      -- "${SCRIPT_DIR}/build-tfa.sh" "${TF_CONFIG}"
)

# Create the project database.
PROJECT_ECD="${ECLAIR_OUTPUT_DIR}/PROJECT.ecd"
find "${ECLAIR_DATA_DIR}" -maxdepth 1 -name "FRAME.*.ecb" \
    | sort | xargs cat \
    | "${ECLAIR_BIN_DIR}/eclair_report" \
          "-create_db='${PROJECT_ECD}'" \
          -load=/dev/stdin


function make_self_contained() {
    dir=$1
    mkdir -p $dir/lib

    cp -r /opt/bugseng/eclair-3.12.0/lib/html $dir/lib

    ${SCRIPT_DIR}/relativize_urls.py $dir
}

${ECLAIR_BIN_DIR}/eclair_report -db=${PROJECT_ECD} \
    -summary_txt=${ECLAIR_OUTPUT_DIR}/../summary_txt \
    -full_txt=${ECLAIR_OUTPUT_DIR}/../full_txt \
    -reports1_html=strictness,${ECLAIR_OUTPUT_DIR}/../full_html/by_strictness/@TAG@.html \
    -full_html=${ECLAIR_OUTPUT_DIR}/../full_html

# summary_txt contains just a single report file not present in full_txt, move it there and be done with it.
mv ${ECLAIR_OUTPUT_DIR}/../summary_txt/by_service.txt ${ECLAIR_OUTPUT_DIR}/../full_txt/
rm -rf ${ECLAIR_OUTPUT_DIR}/../summary_txt
make_self_contained ${ECLAIR_OUTPUT_DIR}/../full_html

# Create the Jenkins reports file.
JENKINS_XML="${ECLAIR_OUTPUT_DIR}/../jenkins.xml"
${ECLAIR_BIN_DIR}/eclair_report -db=${PROJECT_ECD} -reports_jenkins=${JENKINS_XML}


# Compress database to take less disk space in Jenkins archive
xz ${PROJECT_ECD}


cat <<EOF >index.html
<html>
<body>
<h1>MISRA reports</h1>

<p>
TF-A Config: ${TF_CONFIG}
CI Build: <a href="${BUILD_URL}">${BUILD_URL}</a>
</p>

<li><a href="ECLAIR/full_txt/">Full TXT report</a>
<li><a href="ECLAIR/full_html/index.html">Full HTML report</a>
<li><a href="ECLAIR/full_html/by_service.html#strictness/service/first_file&strictness">Report by issue strictness (Mandatory/Required/Advisory) (HTML).</a>
</body>
</html>
EOF
