#!/usr/bin/env bash
#
# Copyright (c) 2019-2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Generate a FVP-TFTF model agnostic YAML template. Note that this template
# is not ready to be sent to LAVA by Jenkins. So in order to produce complete
# file, variables in {UPPERCASE} must be replaced to correct values. This
# file also includes references to ${UPPERCASE} which are just normal shell
# variables, replaced on spot.

ci_root="$(readlink -f "$(dirname "$0")/..")"
source "$ci_root/utils.sh"

. $(dirname $0)/gen_gerrit_meta.sh

expand_template "$(dirname "$0")/lava-templates/fvp-tftf.yaml"
