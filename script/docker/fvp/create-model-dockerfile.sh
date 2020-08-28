#!/bin/bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Creates a dockerfile based on a fvp model (model).

# The scripts takes two argument: the model tarball's filename (first argument)
# and target directory to store the created Dockerfile (second argument)
#

# globals
OS="${OS:-ubuntu}"
OS_VER="${OS_VERSION:-bionic}"
MODEL_DIR="${MODEL_DIR:-/opt/model}"

function usage() {
    echo "Usage: $0 model-tarball target-dir" 1>&2
    exit 1
}

function get_model_model_ver() {
    local tgz=$1
    local arr_model=(${tgz//./ })
    local x=${arr_model[0]##*_}
    local y=${arr_model[1]}
    local z=${arr_model[2]}
    if [ -n "$z" -a "$z" != "tgz" ]; then
    		MODEL_VER="${x}.${y}.${z}"
    else
    		MODEL_VER="${x}.${y}"
    fi
    MODEL=$(echo $tgz | sed "s/_${MODEL_VER}.tgz//")
}

function main() {
    local tarball=$1
    local target_dir=$2

    # get MODEL and MODEL_VER
    get_model_model_ver $tarball

    # check variables are populated
    MODEL="${MODEL:?}"
    MODEL_VER="${MODEL_VER:?}"

    # replace template macros with real model values
    sed -e "s|\${OS}|${OS}|g" \
        -e "s|\${OS_VER}|${OS_VER}|g" \
        -e "s|\${MODEL}|${MODEL}|g" \
        -e "s|\${MODEL_VER}|${MODEL_VER}|g" \
        -e "s|\${MODEL_DIR}|${MODEL_DIR}|g" < dockerfile-template > $target_dir/Dockerfile
}

[ $# -ne 2 ] && usage

tarball=$1; target_dir=$2; main ${tarball} ${target_dir}
