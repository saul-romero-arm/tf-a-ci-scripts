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

# Absolute path of the ECLAIR bin directory.
ECLAIR_BIN_DIR="/opt/bugseng/eclair/bin"

# Directory where this script resides: usually in a directory named "ECLAIR".
SCRIPT_DIR="$(cd "$(dirname "$0")" ; echo "${PWD}")"

# Directory where to put all ECLAIR output and temporary files.
ECLAIR_OUTPUT_DIR="${WORKSPACE}/ECLAIR/out"

TF_CONFIG="$1"

# Automatically export vars
set -a
source ${WORKSPACE}/tf-a-ci-scripts/tf_config/${TF_CONFIG}
set +a

export CC_ALIASES="${CROSS_COMPILE}gcc"
export CXX_ALIASES="${CROSS_COMPILE}g++"
export LD_ALIASES="${CROSS_COMPILE}ld"
export AR_ALIASES="${CROSS_COMPILE}ar"
export AS_ALIASES="${CROSS_COMPILE}as"
export FILEMANIP_ALIASES="cp mv ${CROSS_COMPILE}objcopy"

which ${CROSS_COMPILE}gcc
${CROSS_COMPILE}gcc -v

# ECLAIR binary data directory and workspace.
export ECLAIR_DATA_DIR="${ECLAIR_OUTPUT_DIR}/.data"
# ECLAIR workspace.
export ECLAIR_WORKSPACE="${ECLAIR_DATA_DIR}/eclair_workspace"
# Destination file for the ECLAIR diagnostics.
export ECLAIR_DIAGNOSTICS_OUTPUT="${ECLAIR_OUTPUT_DIR}/DIAGNOSTICS.txt"

# Identifies the particular build of the project.
export ECLAIR_PROJECT_NAME="TF_A_${TF_CONFIG}"
# All paths mentioned in ECLAIR reports that are below this directory
# will be presented as relative to ECLAIR_PROJECT_ROOT.
export ECLAIR_PROJECT_ROOT="${WORKSPACE}/trusted-firmware-a"

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
