#!/bin/bash
#
# Copyright (c) 2021-2022 BUGSENG srl. All rights reserved.
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Common code to setup analysis environment.

# Absolute path of the ECLAIR bin directory.
ECLAIR_BIN_DIR="/opt/bugseng/eclair/bin"

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

# Identifies the particular build of the project.
export ECLAIR_PROJECT_NAME="TF_A_${TF_CONFIG}"
# All paths mentioned in ECLAIR reports that are below this directory
# will be presented as relative to ECLAIR_PROJECT_ROOT.
export ECLAIR_PROJECT_ROOT="${WORKSPACE}/trusted-firmware-a"
