#!/bin/bash
#
# Copyright (c) 2021-2022 BUGSENG srl. All rights reserved.
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

set -ex

env

cd ${WORKSPACE}/trusted-firmware-a
make clean
make ${MAKE_TARGET} -j3 $(cat ${WORKSPACE}/tf-a-ci-scripts/tf_config/$1)
