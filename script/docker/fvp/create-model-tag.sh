#!/bin/bash
#
# Copyright (c) 2010, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Creates a 'tag' based on a fvp model (model).
#
# The script takes a single argument: the model tarball's filename (first argument)
#

function usage() {
    echo "Usage: $0 model-tarball" 1>&2
    exit 1
}

# Create a tag based a on fvp model
function create-tag() {
    local model=$1
    local tag

    # get model basename
    tag=$(basename $model)

    # remove any extension (tgz expected)
    tag=${tag%.*}

    # finally lowercase
    tag=${tag,,}

    echo $tag
}

[ $# -ne 1 ] &&  usage

tarball=$1; create-tag ${tarball}
