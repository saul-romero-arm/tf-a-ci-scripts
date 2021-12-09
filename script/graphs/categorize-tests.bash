#!/usr/bin/env bash

#
# Copyright (c) 2021-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -euo pipefail

# This script plots the categories of tests by group. It does this by combining
# the awk script and gnuplot script of the same name. This script accepts an
# argument, in the format of a grep expression, that allows the tests to be
# filtered before categorization. This script produces the plot as a png on
# stdout.

# Variables
# =========

# I would like to use process-substitution for this, so that we can avoid
# making a file on disk and keep everything in memory, removing the need to
# clean anything up on exit and preventing any chance of polluting the user's
# filesystem. However, when gnuplot is asked to plot from the same file more
# than once, it will seek to the start of the file for every subsequent plot
# after the first. Unix Pipes do not support this operation, and plotting fails
# under these circumstances. Instead, we use an intermediate file, which is
# removed on success.
categories=$(mktemp "XXXXXXX-test-categories.dat")

# We change a portion of the title for our graph based on the argument passed to
# this script.
subtitle=$([[ $# -ge 1 ]] && echo " (Filter: \"$1\")" || true)

# Generate Data into the ${categories} file
# =========================================
#
# The following pipeline is the heart of the implementation, and has four
# stages: find, ???, awk, and sort. The ??? stage of the pipeline is determined
# by the bash if statement, which switches between a filter, when an argument
# is passed, and a passthrough, implemented as `cat -`, when no filter argument
# is passed.
echo '"Name"	"Build-only tests"	"Static checks (MISRA, etc.)"	"Component tests"	"Integration tests (Linux boot, etc.)"' > "${categories}"
find group -type f | ([[ $# -ge 1 ]] && grep -e "$1" - || cat -) |
	awk -f "${0%bash}awk" >> "${categories}"

# Generate a Plot (on stdout)
gnuplot -e "subtitle='${subtitle}'" -c "${0%bash}plot" "${categories}"

# Dump data to stderr
cat "${categories}" 1>&2

# Clean up temporary files
rm "${categories}"
